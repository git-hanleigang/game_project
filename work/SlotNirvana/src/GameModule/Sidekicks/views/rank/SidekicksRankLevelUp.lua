--[[
    荣誉
]]

local SidekicksRankLevelUp = class("SidekicksRankLevelUp", BaseLayer)

function SidekicksRankLevelUp:initDatas(_seasonIdx)
    self.m_seasonIdx = _seasonIdx

    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/rank/Sidekicks_Rank_levelup.csb", _seasonIdx))
    self:setExtendData("SidekicksRankLevelUp")
end

function SidekicksRankLevelUp:initCsbNodes()
    self.m_rank_icon1 = self:findChild("rank_icon_1_24")
    self.m_rank_name1 = self:findChild("rank_name_1_22")
    self.m_rank_icon2 = self:findChild("rank_icon_4_25")
    self.m_rank_name2 = self:findChild("rank_name_2_23")
end

function SidekicksRankLevelUp:initView()
    local lastLv = G_GetMgr(G_REF.Sidekicks):getLastHonorLv()
    local gameData = G_GetMgr(G_REF.Sidekicks):getRunningData()
    local curLv = gameData:getHonorLv()

    local iconPath = "Sidekicks_Common/rank_icon/rank_icon_" .. lastLv .. ".png"
    local namePath = "Sidekicks_Common/rank_name/rank_name_" .. lastLv .. ".png"
    util_changeTexture(self.m_rank_icon1, iconPath)
    util_changeTexture(self.m_rank_name1, namePath)

    local iconPath = "Sidekicks_Common/rank_icon/rank_icon_" .. curLv .. ".png"
    local namePath = "Sidekicks_Common/rank_name/rank_name_" .. curLv .. ".png"
    util_changeTexture(self.m_rank_icon2, iconPath)
    util_changeTexture(self.m_rank_name2, namePath)

    self:setButtonLabelContent("btn_collect", "CHECK YOUR BENEFITS")
end

function SidekicksRankLevelUp:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function SidekicksRankLevelUp:playShowAction()
    gLobalSoundManager:playSound(string.format("Sidekicks_%s/sound/Sidekicks_honor_lv_up_layer_show.mp3", self.m_seasonIdx))
    SidekicksRankLevelUp.super.playShowAction(self, "start")
end

function SidekicksRankLevelUp:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_collect" then
        self:closeUI(function ()
            G_GetMgr(G_REF.Sidekicks):showRankLayer(self.m_seasonIdx)
        end)
    end
end

function SidekicksRankLevelUp:registerListener()
    SidekicksRankLevelUp.super.registerListener(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == G_REF.Sidekicks then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return SidekicksRankLevelUp