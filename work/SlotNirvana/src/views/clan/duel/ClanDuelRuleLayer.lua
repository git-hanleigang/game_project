--[[
    公会对决 - 规则界面
]]
local ClanDuelRuleLayer = class("ClanDuelRuleLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanDuelRuleLayer:ctor()
    ClanDuelRuleLayer.super.ctor(self)
    self:setExtendData("ClanDuelRuleLayer")
    self:setLandscapeCsbName("Club/csd/Duel/DuelRuleLayer.csb")
    self:setPortraitCsbName("Club/csd/Duel/DuelRuleLayer_Vertical.csb")
end

function ClanDuelRuleLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 30)
end

function ClanDuelRuleLayer:registerListener()
    ClanDuelRuleLayer.super.registerListener(self)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.CLAN_DUEL_TIME_OUT) -- 公会对决倒计时结束
end

function ClanDuelRuleLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanDuelRuleLayer