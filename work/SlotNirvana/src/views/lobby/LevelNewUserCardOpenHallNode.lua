--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-10 15:27:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-10 15:30:57
FilePath: /SlotNirvana/src/views/lobby/LevelNewUserCardOpenHallNode.lua
Description: 新手期集卡开启 活动 展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelNewUserCardOpenHallNode = class("LevelNewUserCardOpenHallNode", LevelFeature)

function LevelNewUserCardOpenHallNode:createCsb()
    LevelNewUserCardOpenHallNode.super.createCsb(self)

    self:createCsbNode("Icons/CardOpenhall_NewUser.csb")
    self:runCsbAction("idle", true)

    self.m_showData = G_GetMgr(ACTIVITY_REF.CardOpenNewUser):getHallSlideShowData()
    self:updateAlbumInfoUI()
    if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        -- 双倍 促销奖励 客户端显示* 2  结束实时刷新 金币值
        schedule(self, util_node_handler(self, self.updateAlbumInfoUI), 1)
    end
end

function LevelNewUserCardOpenHallNode:onEnterFinish()
    LevelNewUserCardOpenHallNode.super.onEnterFinish(self)

    -- 掉落卡包 更新数据
    gLobalNoticManager:addObserver(self, "updateAlbumInfoUI", ViewEventType.NOTIFY_UPDATE_CARD_OPEN_SHOW_DATA)
end

function LevelNewUserCardOpenHallNode:updateAlbumInfoUI()
    -- 集卡轮次奖金
    local lbCoins = self:findChild("lb_coins")
    local coins = self.m_showData:getNoviceAlbumCoins()
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
    -- 集卡奖金价值
    local lbWorth = self:findChild("lb_worth")
    local worth = self.m_showData:getCardAlbumUsd()
    if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        -- 双倍 促销奖励 客户端显示* 2  结束实时刷新 金币值
        worth = tonumber(worth) * 2
    end
    lbWorth:setString("$" .. worth)
    util_scaleCoinLabGameLayerFromBgWidth(lbWorth, 200, 1)
end

function LevelNewUserCardOpenHallNode:clickFunc(sender)
    G_GetMgr(ACTIVITY_REF.CardOpenNewUser):showMainLayer({clickFlag = true, popupType = ACT_LAYER_POPUP_TYPE.HALL})
end

return LevelNewUserCardOpenHallNode