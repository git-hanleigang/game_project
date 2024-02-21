--[[
    集卡系统
    卡册选择面板子类 202102赛季
    数据来源于年度开启的赛季
--]]
local CardAlbumView201903 = util_require("GameModule.Card.season201903.CardAlbumView")
local CardAlbumView = class("CardAlbumView", CardAlbumView201903)

-- function CardAlbumView:getCsbName()
--     return string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season202202")
-- end

function CardAlbumView:initDatas(isPlayStart)
    CardAlbumView.super.initDatas(self, isPlayStart)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season202202"))
end

function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season202202.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season202202.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season202202.CardAlbumCell"
end

function CardAlbumView:getAlbumListData()
    local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return normalClans
end

function CardAlbumView:openStatueClanUI()
    -- 开始播放神像界面的入场动画
    -- performWithDelay(self, function()
    CardSysManager:getStatueMgr():showStatueClanUI("CardAlbumView")
    -- end, 20/60)
    -- self:runCsbAction("ruchang", false, function()
    --     -- CardSysManager:getStatueMgr():showStatueClanUI("CardAlbumView")
    --     -- 延迟隐藏，防止漏出游戏大厅界面
    --     performWithDelay(self, function()
    --         self:runCsbAction("idle", true, nil ,60)
    --         CardSysManager:hideCardAlbumView()
    --     end, 1)
    -- end, 60)
end

function CardAlbumView:onEnter()
    CardAlbumView.super.onEnter(self)

    -- 打开神像界面时，主界面播放一个关闭动画
    gLobalNoticManager:addObserver(
        self,
        function()
            self:openStatueClanUI()
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_OPEN
    )
end

return CardAlbumView
