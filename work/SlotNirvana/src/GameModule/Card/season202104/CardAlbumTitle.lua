--[[--
    章节选择界面的标题
]]
local CardAlbumTitle201903 = util_require("GameModule.Card.season201903.CardAlbumTitle")
local CardAlbumTitle = class("CardAlbumTitle", CardAlbumTitle201903)

function CardAlbumTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumTitleRes, "season202104")
end

function CardAlbumTitle:getTimeLua()
    return "GameModule.Card.season202104.CardSeasonTime"
end

--[[-- 赛季新增雕塑buff 开始------------------------------------------------- ]]
function CardAlbumTitle:initCsbNodes()
    CardAlbumTitle.super.initCsbNodes(self)
    self.m_nodeStatueBuff = self:findChild("diaosu_buff")
    self.m_spCoin = self:findChild("jinbi")
    self.m_efBgNode = self:findChild("ef_node_bg")
end

function CardAlbumTitle:initView()
    CardAlbumTitle.super.initView(self)
    self:initStatueBuffNode()

    -- 特效
    local efNode = util_createAnimation("CardRes/season202104/cash_album_title_ef_bg_guang.csb")
    if self.m_efBgNode and efNode then
        self.m_efBgNode:addChild(efNode)
        efNode:playAction("idle", true)
    end
end

function CardAlbumTitle:initStatueBuffNode()
    self.m_nodeStatueBuff:removeAllChildren()
    local nMuti = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_COMPLETE_COIN_BONUS)
    if nMuti and nMuti > 0 then
        -- local statueBuffUI = util_createView("GameModule.Card.season202104.CardBuffTipNode", nMuti)
        local albumId = CardSysRuntimeMgr:getSelAlbumID()
        local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
        if _logic then
            local statueBuffUI = _logic:createCardSpecialGameBuffNode(nMuti)
            self.m_nodeStatueBuff:addChild(statueBuffUI)
        end
    end
end

function CardAlbumTitle:updateUI(isPlayStart)
    CardAlbumTitle.super.updateUI(self, isPlayStart)
    local UIList = {}
    table.insert(UIList, {node = self.m_spCoin, anchor = cc.p(0.5, 0.5)})

    self:updateLabelSize({label = self.m_lb_coins}, 410)
    local scale = self.m_lb_coins:getScale()
    table.insert(UIList, {node = self.m_lb_coins, alignX = 5, scale = scale, anchor = cc.p(0.5, 0.5)})
    util_alignCenter(UIList)
end

--[[-- 赛季新增雕塑buff 结束------------------------------------------------- ]]
function CardAlbumTitle:onEnter()
    CardAlbumTitle.super.onEnter(self)

    -- -- TODO:MAQUN 赛季结束发送消息刷新buff标签
    -- gLobalNoticManager:addObserver(self, function(target, params)
    --     self:initStatueBuffNode()
    -- end, "CARD_SEASON_OVER")

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initStatueBuffNode()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initStatueBuffNode()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

return CardAlbumTitle
