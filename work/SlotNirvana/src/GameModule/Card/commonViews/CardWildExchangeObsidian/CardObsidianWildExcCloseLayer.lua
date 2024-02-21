--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-28 15:50:57
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-28 15:51:20
FilePath: /SlotNirvana/src/GameModule/Card/commonViews/CardWildExchangeObsidian/CardObsidianWildExcCloseLayer.lua
Description: 集卡 黑耀卡 wild关闭 二次确认界面
--]]
local CardObsidianWildExcCloseLayer = class("CardObsidianWildExcCloseLayer", BaseLayer)

function CardObsidianWildExcCloseLayer:initDatas(_expire, _confirmCB)
    self.m_expire = _expire
    self.m_confirmCB = _confirmCB

    self.m_seasonId = G_GetMgr(G_REF.ObsidianCard):getSeasonId()

    self:setExtendData("CardObsidianWildExcCloseLayer")
    self:setName("CardObsidianWildExcCloseLayer")
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(string.format("CardRes/CardObsidian_%s/csb/wild/cash_wild_exchange_quit.csb", self.m_seasonId))
    self:addClickSound({"btn_yes", "btn_no"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

-- 初始化UI --
function CardObsidianWildExcCloseLayer:initView()
    CardObsidianWildExcCloseLayer.super.initView(self)
   
    -- 过期时间
    self.m_scheduler = schedule(self, function()
        self:updateCountdonwUI(self.m_expire)
    end, 1)
    self:updateCountdonwUI(self.m_expire)
end
function CardObsidianWildExcCloseLayer:updateCountdonwUI(_expireSec)
    local lbExpireTime = self:findChild("lb_expireTime")
    local timeStr, bOver = util_daysdemaining(_expireSec, true)
    if bOver then
        self:clearScheduler()
        self:closeUI()
    end
    lbExpireTime:setString(timeStr)
end

function CardObsidianWildExcCloseLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardObsidianWildExcCloseLayer.super.playShowAction(self, "show", false)
end

function CardObsidianWildExcCloseLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardObsidianWildExcCloseLayer:playHideAction()
    CardObsidianWildExcCloseLayer.super.playHideAction(self, "over", false)
end

-- 点击事件 --
function CardObsidianWildExcCloseLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_yes" then
        -- stay 留下来直接关闭界面
        self:closeUI()
    elseif name == "btn_no" then
        -- close 要关闭所有界面
        self:closeUI(self.m_confirmCB)
    end
end

function CardObsidianWildExcCloseLayer:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardObsidianWildExcCloseLayer.super.closeUI(self, _cb)
end

-- 清楚定时器
function CardObsidianWildExcCloseLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return CardObsidianWildExcCloseLayer