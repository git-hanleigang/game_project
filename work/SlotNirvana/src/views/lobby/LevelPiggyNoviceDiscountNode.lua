--
-- 大厅展示图 小猪商城的新手折扣活动
--

local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelPiggyNoviceDiscountNode = class("LevelPiggyNoviceDiscountNode", LevelFeature)

function LevelPiggyNoviceDiscountNode:createCsb()
    self:createCsbNode("newIcons/Level_PiggyNoviceDiscount.csb")

    self.m_discount = self:findChild("Text_1")

    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if piggyBankData then
        self.m_discount:setString(piggyBankData:getNoviceFirstDiscount() .. "%")
    end
end

--点击回调
function LevelPiggyNoviceDiscountNode:clickFunc(sender)
    local name = sender:getName()
    self:clickLayer(name)
end

--点击回调
function LevelPiggyNoviceDiscountNode:MyclickFunc()
    self:clickLayer()
end

function LevelPiggyNoviceDiscountNode:clickLayer(name)
    gLobalSendDataManager:getLogIap():setEntryOrder(self.m_index)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyDisplay")
    -- 打开小猪面板
    G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, name, DotUrlType.UrlName, true, DotEntrySite.LobbyDisplay, DotEntryType.Lobby)
        end
    end)    
end

return LevelPiggyNoviceDiscountNode
