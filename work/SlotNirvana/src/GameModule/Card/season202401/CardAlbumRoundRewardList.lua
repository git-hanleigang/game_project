--[[
]]
local CardAlbumRoundRewardList = class("CardAlbumRoundRewardList", BaseView)

function CardAlbumRoundRewardList:getCsbName()
    return "CardRes/season202401/cash_album_title_list.csb"
end

function CardAlbumRoundRewardList:initDatas()
    self.m_rewardCellLua = "GameModule.Card.season202401.CardAlbumRoundRewardCell"
end

function CardAlbumRoundRewardList:initCsbNodes()
    self.m_nodeRounds = {}
    for i = 1, 3 do
        local round = self:findChild("node_round_" .. i)
        table.insert(self.m_nodeRounds, round)
    end
end

function CardAlbumRoundRewardList:initUI()
    CardAlbumRoundRewardList.super.initUI(self)
    self:initRewards()
end

function CardAlbumRoundRewardList:initRewards()
    self.m_rewards = {}
    for i = 1, #self.m_nodeRounds do
        local reward = util_createView(self.m_rewardCellLua, i)
        self.m_nodeRounds[i]:addChild(reward)
        table.insert(self.m_rewards, reward)
    end
end

function CardAlbumRoundRewardList:playStart(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            self:playIdle()
            if _over then
                _over()
            end
        end,
        30
    )
end

function CardAlbumRoundRewardList:playIdle()
    self:runCsbAction("idle", true, _over, 30)
end

function CardAlbumRoundRewardList:playOver(_over)
    self:runCsbAction("over", false, _over, 30)
end

return CardAlbumRoundRewardList
