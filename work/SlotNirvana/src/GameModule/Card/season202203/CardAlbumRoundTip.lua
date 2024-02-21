--[[
    轮次小标签
]]
local CardAlbumRoundTip = class("CardAlbumRoundTip", BaseView)
function CardAlbumRoundTip:getCsbName()
    return "CardRes/season202203/cash_album_round.csb"
end

function CardAlbumRoundTip:initCsbNodes()
    self.m_nodeRound = self:findChild("node_round")
    self.m_lbRound = self:findChild("lb_round")
end

function CardAlbumRoundTip:initUI()
    CardAlbumRoundTip.super.initUI(self)
    self:initRound()
end

function CardAlbumRoundTip:initRound()
    local round = self:getRound()
    -- 从第二轮开始显示
    -- self.m_nodeRound:setVisible(round > 0)
    -- 服务器下发的round是从0开始的
    local str = gLobalLanguageChangeManager:getStringByKey("CardAlbumRoundTip:lb_round")
    self.m_lbRound:setString(string.format(str, round))
end

function CardAlbumRoundTip:getRound()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return (albumData:getRound() or 0) + 1
    end
    return 1
end

function CardAlbumRoundTip:onEnter()
    CardAlbumRoundTip.super.onEnter(self)
    -- 轮次更改
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initRound()
        end,
        CardSysConfigs.ViewEventType.CARD_ALBUM_ROUND_CHANGE
    )
end

return CardAlbumRoundTip
