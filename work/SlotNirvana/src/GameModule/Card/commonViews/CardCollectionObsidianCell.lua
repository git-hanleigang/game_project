--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-10-20 10:58:41
]]
--[[--
    黑曜卡历史赛季入口
]]
local BaseView = util_require("base.BaseView")
local CardCollectionObsidianCell = class("CardCollectionObsidianCell", BaseView)

function CardCollectionObsidianCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardCollectionCellRes, "season" .. CardSysRuntimeMgr:getCurAlbumID())
end

-- 初始化
function CardCollectionObsidianCell:initUI()
    self:createCsbNode(self:getCsbName())
    self:initNode()
end

function CardCollectionObsidianCell:initNode()
    self.m_spSeason = self:findChild("sp_seasonIcon")

    self.m_dlNode = self:findChild("Node_download")
    self.m_dlPro = self:findChild("Node_DL_pro")
    self.m_proBar = self:findChild("LoadingBar_1")
    self.m_proBarText = self:findChild("BitmapFontLabel_1")

    self.m_touch = self:findChild("touch")
end

function CardCollectionObsidianCell:initView(seasonId)
    self.m_dlNode:setVisible(false)
    self.m_dlPro:setVisible(false)

    self.m_touch:setSwallowTouches(false)
    self:addClick(self.m_touch)
    util_changeTexture(self.m_spSeason, "CardsBase201903/CardRes/Other/Collection_saishi_icon_obsidian.png")
end

function CardCollectionObsidianCell:clickFunc(sender)
    local name = sender:getName()
    -- 请求进入以往集卡
    if name == "touch" then
        self:enterAlbum()
    end
end

function CardCollectionObsidianCell:enterAlbum()
    local view = util_createView("GameModule.Card.commonViews.CardCollectionObsidianScrollUI")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CardCollectionObsidianCell:onEnter()
    CardCollectionObsidianCell.super.onEnter(self)
end

return CardCollectionObsidianCell