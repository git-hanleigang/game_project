--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-18 10:56:51
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-18 11:16:01
FilePath: /SlotNirvana/src/views/lobby/LevelCardNoviceSaleHallNode.lua
Description: 新手期集卡 促销  展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelCardNoviceSaleHallNode = class("LevelCardNoviceSaleHallNode", LevelFeature)

function LevelCardNoviceSaleHallNode:initCsbNodes()
    LevelCardNoviceSaleHallNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function LevelCardNoviceSaleHallNode:createCsb()
    LevelCardNoviceSaleHallNode.super.createCsb(self)

    self:createCsbNode("NewUserAlbum_AlbumSale/Icons/Activity_NewUserAlbum_AlbumSale_Hall.csb")
    self:runCsbAction("idle", true)

    self.m_showData = G_GetMgr(G_REF.CardNoviceSale):getData()
    self:updateSaleInfoUI()
    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()
end

function LevelCardNoviceSaleHallNode:updateSaleInfoUI()
    -- 集卡轮次奖金
    local lbCoins = self:findChild("lb_coin")
    local coins = self.m_showData:getCoins()
    lbCoins:setString(util_formatCoins(coins, 6))
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = lbCoins, alignX = 5}
        }
    )

    self:setButtonLabelContent("btn_go", "GET IT")
end

function LevelCardNoviceSaleHallNode:onUpdateSec()
    local expireAt = self.m_showData:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if not G_GetMgr(G_REF.CardNoviceSale):isSaleRunning() then
        self:clearScheduler()
        gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_SALE_HALL_SLIDE)
    end
end

-- 清楚定时器
function LevelCardNoviceSaleHallNode:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function LevelCardNoviceSaleHallNode:clickFunc(sender)
    G_GetMgr(G_REF.CardNoviceSale):showSaleLayer()
end

return LevelCardNoviceSaleHallNode