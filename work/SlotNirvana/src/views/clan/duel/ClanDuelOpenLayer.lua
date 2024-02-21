--[[
    公会对决 - 开启界面
--]]
local ClanDuelOpenLayer = class("ClanDuelOpenLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanDuelOpenLayer:ctor()
    ClanDuelOpenLayer.super.ctor(self)
    self:setExtendData("ClanDuelOpenLayer")
    self:setLandscapeCsbName("Club/csd/Duel/Duel_open.csb")
    gLobalDataManager:setBoolByField("isFirstPopClanDuelOpenLayer", false)
end

function ClanDuelOpenLayer:initDatas()
    local clanData = ClanManager:getClanData()
    self.m_duelData = clanData:getClanDuelData()
    self.m_clanInfo = clanData:getClanSimpleInfo()
    self.m_duelData:setDuelRedPoints(0)
end

function ClanDuelOpenLayer:initCsbNodes()
    -- reward
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_node_item = self:findChild("node_item")
    -- logo
    self.m_spTeamLogoBG = self:findChild("sp_clubIconBg")
    self.m_spTeamLogo = self:findChild("sp_clubIcon")
end

function ClanDuelOpenLayer:initView()
    -- 公会Logo
    self:initClanLogo()
    -- 奖励信息
    self:initReward()
end

function ClanDuelOpenLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    ClanDuelOpenLayer.super.playShowAction(self, "start")
end

function ClanDuelOpenLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

-- 公会 徽章logo
function ClanDuelOpenLayer:initClanLogo()
    local clanLogo = self.m_clanInfo:getTeamLogo()
    local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
    local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
    util_changeTexture(self.m_spTeamLogoBG, imgBgPath)
    util_changeTexture(self.m_spTeamLogo, imgPath)
end

function ClanDuelOpenLayer:initReward()
    if not self.m_duelData then
        return
    end
    local coins = self.m_duelData:getCoins()
    local items = self.m_duelData:getItems()
    local coinsStr = ""
    local rewardScale = 0.7
    local nodeItemSize = cc.size(0, 0)

    if coins and coins > 0 then
        coinsStr = coinsStr .. util_formatCoins(coins, 6)
    end

    if items and table.nums(items) > 0 then
        coinsStr = coinsStr .. "+"
        local itemUiList = {}
        local item_width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
        nodeItemSize.height = item_width
        for i, shopItemData in ipairs(items) do
            local shopItemUI = gLobalItemManager:createRewardNode(shopItemData, ITEM_SIZE_TYPE.TOP)
            if shopItemUI ~= nil then
                self.m_node_item:addChild(shopItemUI)
                shopItemUI:setScale(rewardScale)
                table.insert(
                    itemUiList,
                    {node = shopItemUI, alignX = 0, size = cc.size(item_width, item_width), anchor = cc.p(0.5, 0.5)}
                )
                nodeItemSize.width =  nodeItemSize.width + item_width
            end
        end
        util_alignLeft(itemUiList)
    end

    nodeItemSize = cc.size(nodeItemSize.width * rewardScale, nodeItemSize.height * rewardScale)

    self.m_lb_coin:setString(coinsStr)

    local uiList = {}
    uiList[#uiList + 1] = {node = self.m_sp_coin, alignX = 2}
    uiList[#uiList + 1] = {node = self.m_lb_coin, alignX = 2}
    uiList[#uiList + 1] = {node = self.m_node_item, size = nodeItemSize}
    util_alignCenter(uiList)
end

function ClanDuelOpenLayer:clickFunc(sender) 
    if self.m_isAnimationing then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_start" then
        self:closeUI(function()
            ClanManager:popClanDuelMainLayer()
        end)
    end
end

return ClanDuelOpenLayer