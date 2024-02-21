--[[
    特殊卡册黑曜卡
    卡册选择面板子类
    数据来源于年度开启的赛季
--]]
local CardCollectionObsidianScrollUI = class("CardCollectionObsidianScrollUI", BaseLayer)

function CardCollectionObsidianScrollUI:ctor()
    CardCollectionObsidianScrollUI.super.ctor(self)
    self:setLandscapeCsbName("CardRes/CardObsidianCollection/cash_album_layer.csb")
    G_GetMgr(G_REF.ObsidianCard):registerNeedHideLayer("CardCollectionObsidianScrollUI", self)
end

function CardCollectionObsidianScrollUI:initDatas()
    self.m_shortYearsData = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
end

function CardCollectionObsidianScrollUI:initCsbNodes()
    self.m_titleNode = self:findChild("Node_title")
    self.m_albumNode = self:findChild("Node_zhangjie")
    self.m_touchLayer = self:findChild("touch")
    self.m_touchLayer:setSwallowTouches(false)
end

function CardCollectionObsidianScrollUI:getObsidianCellLua()
    return "GameModule.Card.commonViews.CardCollectionObsidianScrollCell"
end

function CardCollectionObsidianScrollUI:getTitleCsbName()
    return "CardRes/CardObsidianCollection/cash_album_title1.csb"
end

function CardCollectionObsidianScrollUI:onShowedCallFunc()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )

    -- performWithDelay(
    --     self,
    --     function()
    --         self:initAlbumList(true)
    --         util_setCascadeOpacityEnabledRescursion(self, true)
    --     end,
    --     0.65
    -- )
    self:initAlbumList(true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 初始化UI --
function CardCollectionObsidianScrollUI:initView()
    self:initAdapt()
    self:initTitle()
end

function CardCollectionObsidianScrollUI:initAdapt()
    -- -- 适配上UI
    -- local pos = cc.p(self.m_titleNode:getPosition())
    -- local worldPos = self.m_titleNode:getParent():convertToWorldSpace(cc.p(self.m_titleNode:getPosition()))
    -- local localPos = self.m_titleNode:getParent():convertToNodeSpace(cc.p(worldPos.x, display.height))
    -- self.m_titleNode:setPositionY(localPos.y)
end

function CardCollectionObsidianScrollUI:initTitle()
    if not self.m_titleUI then
        self.m_titleUI = util_createAnimation(self:getTitleCsbName())
        self.m_titleNode:addChild(self.m_titleUI)
    end
end

function CardCollectionObsidianScrollUI:initAlbumList(isPlayStart)
    local cardClanData = self:getAlbumListData()
    if cardClanData ~= nil then
        if not self.uiList then
            self.uiList = {}
            for k, v in pairs(cardClanData) do
                -- 创建章节cell
                local albumCell = util_createView(self:getObsidianCellLua(), v)
                table.insert(self.uiList, albumCell)
            end

            if #self.uiList <= 3 then
                self:initAlbumCellPos()
                return
            end

            local circleScrollUI = util_createView("base.CircleScrollUI")
            circleScrollUI:setMargin(0)
            circleScrollUI:setMarginXY(120, 20)
            circleScrollUI:setMaxTopYPercent(0.5)
            circleScrollUI:setTopYHeight(120)
            circleScrollUI:setMaxAngle(20)
            circleScrollUI:setRadius(2450)
            if isPlayStart then
                circleScrollUI:setPlayToLeftAnimInfo(0.2, 4)
                for i = 1, #self.uiList do
                    local albumCell = self.uiList[i]
                end
            end
            circleScrollUI:setUIList(self.uiList)

            local scale = self:findChild("root"):getScale()
            circleScrollUI:setDisplaySize(display.width / scale, 525)
            circleScrollUI:setPosition(-display.width / scale / 2, -2270 - display.height / 2)
            self.m_albumNode:addChild(circleScrollUI)
            util_setCascadeOpacityEnabledRescursion(self, true)
        else
            for i = 1, #self.uiList do
                local albumCell = self.uiList[i]
            end
        end
    end
end

function CardCollectionObsidianScrollUI:initAlbumCellPos()
    local len = #self.uiList
    for i = 1, len do
        local albumCell = self.uiList[i]
        local width = albumCell:getContentSize().width
        local angle = -((len / 2) - 0.5) * 20 + 20 * (i - 1)
        local posX = -((len / 2) - 0.5) * width + width * (i - 1)
        local posY = -math.abs(math.sin(angle / 180 * math.pi) * 200)
        albumCell:setPosition(posX, posY)
        albumCell:setRotation(angle)
        self.m_albumNode:addChild(albumCell)
    end
end

function CardCollectionObsidianScrollUI:getAlbumListData()
    if self.m_shortYearsData then
        local list = self.m_shortYearsData:getCollectionShowObsitionCard()
        if list and #list > 0 then
            return list
        end
    end
    return nil
end

function CardCollectionObsidianScrollUI:onEnter()
    CardCollectionObsidianScrollUI.super.onEnter(self)
end

function CardCollectionObsidianScrollUI:onExit()
    CardCollectionObsidianScrollUI.super.onExit(self)
    G_GetMgr(G_REF.ObsidianCard):releaseNeedHideLayer("CardCollectionObsidianScrollUI", self)
end

function CardCollectionObsidianScrollUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return CardCollectionObsidianScrollUI
