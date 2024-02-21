--[[--
    集卡下UI
]]
local CardSeasonBottom = class("CardSeasonBottom", BaseView)

function CardSeasonBottom:initDatas()
    self.m_storeLuaPath = "GameModule.Card.season202304.CardSeasonBottomStore"
    self.m_miniGameLuaPath = "GameModule.Card.season202304.CardSeasonBottomMiniGame"
    self.m_nadoMachineLuaPath = "GameModule.Card.season202304.CardSeasonBottomNadoMachine"
    self.m_nadoObsidianLuaPath = "GameModule.Card.season202304.CardSeasonBottomObsidian_"
    self.m_nodeList = {}
end

function CardSeasonBottom:initCsbNodes()
    self.m_nodeStore = self:findChild("node_store")
    self.m_nodeMiniGame = self:findChild("node_miniGame")
    self.m_nodeNadoMachine = self:findChild("node_nadoMachine")
    self.m_nodeSpree = self:findChild("node_spree")

    self.m_sp_bg = self:findChild("sp_bg")
    self.m_sp_spree_bg = self:findChild("sp_spree_bg")

    -- 202304 的特殊处理 这个背景图片不知道有什么用，影响前两个背景图的显示（重叠显示），所以设置成不显示
    -- local serverSeasonId = CardSysRuntimeMgr:getCurAlbumID()
    self.m_sp_pay_bg = self:findChild("sp_pay_bg")
    if self.m_sp_pay_bg then
        self.m_sp_pay_bg:setVisible(false)
    end

    self.m_nodeMoreAwardSale = self:findChild("node_albummoreawardsale")
end

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season202304")
end

function CardSeasonBottom:initUI()
    CardSeasonBottom.super.initUI(self)

    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if not CardSysRuntimeMgr:isPastAlbum(albumID) then
        -- 按摆放位置初始化节点
        self:initNadoSpree()
        self:initStore()
        self:initMiniGame()
        self:initNadoMachine()
        self:showDownTimer()
        self:initCloseTimer()
    end
    self:initMoreAwardSale()
    self:refreshNodePos()
    self:playStart()
end

function CardSeasonBottom:initMoreAwardSale()
    if not self.m_moreAwardSale and self.m_nodeMoreAwardSale then
        local node = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):getSaleNode()
        if node then
            self.m_nodeMoreAwardSale:addChild(node)
            self.m_moreAwardSale = node
        end
    end
end

function CardSeasonBottom:initCloseTimer()
    local expireAt = CardSysManager:getSeasonExpireAt()
    if not expireAt then
        self:hideAllNode()
        return
    end
    self:stopCloseTimer()
    self.m_closeTimer = util_schedule(self, function()
        if not tolua.isnull(self) then
            local leftTime = util_getLeftTime(expireAt * 1000)
            if leftTime <= 0 then
                self:hideAllNode()
                self:stopCloseTimer()
            end
        end
    end, 1)
end

function CardSeasonBottom:stopCloseTimer()
    if self.m_closeTimer then
        self:stopAction(self.m_closeTimer)
        self.m_closeTimer = nil
    end
end

function CardSeasonBottom:hideAllNode()
    self.m_nodeStore:setVisible(false)
    self.m_nodeMiniGame:setVisible(false)
    self.m_nodeNadoMachine:setVisible(false)
    self.m_nodeSpree:setVisible(false)
end

function CardSeasonBottom:initStore()
    if not self.m_storeLuaPath then
        return
    end
    self.m_store = util_createView(self.m_storeLuaPath)
    self.m_nodeStore:addChild(self.m_store)
    table.insert(self.m_nodeList, self.m_nodeStore)
end

function CardSeasonBottom:initMiniGame()
    if not self.m_miniGameLuaPath then
        return
    end
    self.m_miniGame = util_createView(self.m_miniGameLuaPath)
    self.m_nodeMiniGame:addChild(self.m_miniGame)
    table.insert(self.m_nodeList, self.m_nodeMiniGame)
end

function CardSeasonBottom:initNadoMachine()
    if not self.m_nadoMachineLuaPath then
        return
    end
    self.m_nadoMachine = util_createView(self.m_nadoMachineLuaPath)
    self.m_nodeNadoMachine:addChild(self.m_nadoMachine)
    table.insert(self.m_nodeList, self.m_nodeNadoMachine)
end

function CardSeasonBottom:initNadoSpree()
    if not self.m_nadoObsidianLuaPath then
        return
    end
    -- local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData()
    -- if not data then
    --     return
    -- end
    local obsidianYearsData = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
    if not obsidianYearsData then
        return
    end
    local albumId = G_GetMgr(G_REF.ObsidianCard):getCurAlbumID()
    local day, isOver = util_daysdemaining(obsidianYearsData:getExpireAt(albumId), true)
    if isOver then
        return
    end
    if not self.m_spree then
        local seasonId = G_GetMgr(G_REF.ObsidianCard):getSeasonId()
        if seasonId then
            self.m_spree = util_createView(self.m_nadoObsidianLuaPath .. tostring(seasonId))
            if self.m_spree then
                self.m_nodeSpree:addChild(self.m_spree)
                table.insert(self.m_nodeList, 1, self.m_nodeSpree)
            end
        end
    end
end

function CardSeasonBottom:removeSpreeNode()
    if not tolua.isnull(self.m_spree) then
        local pos = table.indexof(self.m_nodeList, self.m_nodeSpree)
        table.remove(self.m_nodeList, pos)
        self.m_spree:removeFromParent()
        self.m_spree = nil
    end
end

function CardSeasonBottom:refreshNodePos()
    local len = #self.m_nodeList
    if len <= 3 then
        self.m_sp_bg:setVisible(true)
        self.m_sp_spree_bg:setVisible(false)
    else
        self.m_sp_bg:setVisible(false)
        self.m_sp_spree_bg:setVisible(true)
    end
    for i = 1, len do
        local node = self.m_nodeList[i]
        local pos = -(len / 2 - 0.5) * 200 + (i - 1) * 200
        node:setPositionX(pos)
    end
end

function CardSeasonBottom:playStart(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            if _over then
                _over()
            end
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function CardSeasonBottom:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

--显示倒计时
function CardSeasonBottom:showDownTimer()
    local albumId = G_GetMgr(G_REF.ObsidianCard):getCurAlbumID()
    local obsidianYearsData = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
    if not obsidianYearsData then
        return
    end
    self.m_expireAt = obsidianYearsData:getExpireAt(albumId)

    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function CardSeasonBottom:updateLeftTime()
    if self.m_expireAt and self.m_expireAt > 0 then
        local day, isOver = util_daysdemaining(self.m_expireAt, true)
        if isOver then
            if not self.m_spree then
                return
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TIMEOUT, { name = G_REF.ObsidianCard })
            self:removeSpreeNode()
            self:refreshNodePos()
        else
            if self.m_spree then
                self.m_spree:setTimeStr(day)
                return
            end
            self:initNadoSpree()
            self:refreshNodePos()
        end
    else
        if not self.m_spree then
            return
        end
        self:removeSpreeNode()
        self:refreshNodePos()
    end
end

function CardSeasonBottom:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function CardSeasonBottom:onEnter()
    CardSeasonBottom.super.onEnter(self)

    -- 限时集卡多倍奖励
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initMoreAwardSale()
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_UPDATE_DATA
    )
end

return CardSeasonBottom
