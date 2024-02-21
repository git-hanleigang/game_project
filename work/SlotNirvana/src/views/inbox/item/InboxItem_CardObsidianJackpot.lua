--[[--
    黑曜卡抽奖结束后发奖
]]

local AlbumCfg = {
    ["900101"] = {season = 1, name = "Spree"},
    ["900102"] = {season = 2, name = "Xmas"},
    ["900103"] = {season = 3, name = "Paddy"},
    ["900104"] = {season = 4, name = "Zombie"},
    ["900105"] = {season = 5, name = "Freedom"},
    ["900106"] = {season = 6, name = "BDay"},
}

local InboxItem_baseReward = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_CardObsidianJackpot = class("InboxItem_CardObsidianJackpot", InboxItem_baseReward)

function InboxItem_CardObsidianJackpot:initDatasFinish()
    -- 发奖时赛季已经结束了，这里手动写死，每次新赛季换皮都得改这里
    self.m_curAlbumId = "900101"
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        if extraData and extraData.albumId then
            self.m_curAlbumId = extraData.albumId
        end
    end
    self.m_seasonId = 1
    self.m_seasonName = "Spree"
    local cfg = AlbumCfg[self.m_curAlbumId]
    if cfg then
        self.m_seasonId = cfg.season
        self.m_seasonName = cfg.name
    end
end

function InboxItem_CardObsidianJackpot:getCsbName()
    return "InBox/InboxItem_CardObsidianJackpot.csb"
end

-- 描述说明
function InboxItem_CardObsidianJackpot:getDescStr()
    return  self.m_seasonName .. " Obsidian Album Jackpot", "Here's your share of the Jackpot."
end

function InboxItem_CardObsidianJackpot:initView()
    self:initData()
    self:initDesc()
    self:alignUI()
    self:initIconUI()
end

function InboxItem_CardObsidianJackpot:initIconUI()
    self.m_spLogo = self:findChild("sp_icon")
    local path = "InBox/ui_CardObsidianJackpot/CardObsidian_" .. self.m_seasonId .. ".png"
    if util_IsFileExist(path) then
        util_changeTexture(self.m_spLogo, path)
    end
end

function InboxItem_CardObsidianJackpot:collectMailSuccess()
    local coins = toLongNumber(0)
    coins:setNum(self.m_coins)
    if not (toLongNumber(coins) > toLongNumber(0)) then
        if not tolua.isnull(self) then
            self:removeSelfItem()
        end
        return
    end
    local rank = 0
    local extra = self.m_mailData.extra
    if extra ~= nil and extra ~= "" then
        local extraData = cjson.decode(extra)
        rank = extraData.rank or 0
    end
    local function clickFunc()
        if not tolua.isnull(self) then
            InboxItem_CardObsidianJackpot.super.collectMailSuccess(self)
        end
    end
    local view = G_GetMgr(G_REF.ObsidianCard):showJackpotRewardLayer(coins, rank, clickFunc, self.m_seasonId)
    if view == nil then
        local itemList = {}
        itemList[#itemList+1] = gLobalItemManager:createLocalItemData("Coins", coins)
        view = gLobalItemManager:createRewardLayer(itemList, clickFunc, coins)
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

function InboxItem_CardObsidianJackpot:flyBonusGameCoins(_callback)
    if _callback then
        _callback()
    end
    if not tolua.isnull(self) then
        self:removeSelfItem()
    end
end

return InboxItem_CardObsidianJackpot
