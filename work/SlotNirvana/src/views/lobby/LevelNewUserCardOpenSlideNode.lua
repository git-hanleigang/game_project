--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-10 15:11:33
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-10 15:11:53
FilePath: /SlotNirvana/src/views/lobby/LevelNewUserCardOpenSlideNode.lua
Description:  新手期集卡开启 活动  轮播图
--]]
local LevelNewUserCardOpenSlideNode = class("LevelNewUserCardOpenSlideNode", BaseView)

function LevelNewUserCardOpenSlideNode:initUI()
    LevelNewUserCardOpenSlideNode.super.initUI(self)

    self.m_showData = G_GetMgr(ACTIVITY_REF.CardOpenNewUser):getHallSlideShowData()
    self.m_bCheckGetLocalData = true
    self:updateAlbumInfoUI()
    self:runCsbAction("idle", true)
    if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        -- 双倍 促销奖励 客户端显示* 2  结束实时刷新 金币值
        schedule(self, util_node_handler(self, self.updateAlbumInfoUI), 1)
    end
end

function LevelNewUserCardOpenSlideNode:onEnterFinish()
    LevelNewUserCardOpenSlideNode.super.onEnterFinish(self)

    -- 掉落卡包 更新数据
    gLobalNoticManager:addObserver(self, "onUpdateAlbumInfoUIEvt", ViewEventType.ONRECIEVE_CARDS_ALBUM_REQ_SUCCESS)
    gLobalNoticManager:addObserver(self, "onForcecUpdateAlbumInfoUIEvt", ViewEventType.NOTIFY_UPDATE_CARD_OPEN_SHOW_DATA)
end

function LevelNewUserCardOpenSlideNode:getCsbName()
    return "Icons/CardOpenslide_NewUser.csb"
end

function LevelNewUserCardOpenSlideNode:onUpdateAlbumInfoUIEvt()
    self.m_bCheckGetLocalData = true
    self:updateAlbumInfoUI()
end
function LevelNewUserCardOpenSlideNode:onForcecUpdateAlbumInfoUIEvt()
    self.m_bCheckGetLocalData = false
    self:updateAlbumInfoUI()
end

-- self.m_bCheckGetLocalData 使用检查使用 本地计算 的卡册数据
function LevelNewUserCardOpenSlideNode:updateAlbumInfoUI()
    local maxProgAlbumData = self.m_showData:getMaxProgAlbumData()
    local coins = self.m_showData:getSlideShowCardClanCoins()
    local logo = self.m_showData:getSlideShowCardClanLogo()
    local cur = self.m_showData:getSlideShowCardClanNum()
    local max = self.m_showData:getSlideShowCardClanTotal()
    if maxProgAlbumData and self.m_bCheckGetLocalData then
        coins = tonumber(maxProgAlbumData.coins) or 0
        logo = CardResConfig.getCardClanIcon(maxProgAlbumData.clanId)
        cur = CardSysRuntimeMgr:getClanCardTypeCount(maxProgAlbumData.cards)
        max = #maxProgAlbumData.cards
    end
    -- 集卡卡册奖金
    local lbCoins = self:findChild("lb_coins")
    if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        -- 双倍 促销奖励 客户端显示* 2  结束实时刷新 金币值
        coins = tonumber(coins) * 2
    end
    lbCoins:setString(util_formatCoins(coins, 6))
    util_alignCenter(
        {
            {node = self:findChild("sp_coins")},
            {node = lbCoins, alignX = 5}
        }
    )

    -- 卡册封面
    local nodeLogo = self:findChild("node_logo")
    nodeLogo:removeAllChildren()
    local spLogo = util_createSprite(logo, true)
    if spLogo then
        nodeLogo:addChild(spLogo)
    end

    -- 卡册收集进度
    local lbProg = self:findChild("lb_bar")
    local loadingBarProg = self:findChild("LoadingBar_1")
    loadingBarProg:setPercent(math.floor(cur / max * 100))
    lbProg:setString(cur.. "/" .. max)
end

--点击回调
function LevelNewUserCardOpenSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelNewUserCardOpenSlideNode:clickLayer(name)
    G_GetMgr(ACTIVITY_REF.CardOpenNewUser):showMainLayer({clickFlag = true, popupType = ACT_LAYER_POPUP_TYPE.SLIDE})
end

return LevelNewUserCardOpenSlideNode