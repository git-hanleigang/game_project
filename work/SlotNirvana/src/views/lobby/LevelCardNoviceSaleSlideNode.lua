--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-20 12:13:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-20 14:14:30
FilePath: /SlotNirvana/src/views/lobby/LevelCardNoviceSaleSlideNode.lua
Description: 新手期集卡 促销 轮播图
--]]
local LevelCardNoviceSaleSlideNode = class("LevelCardNoviceSaleSlideNode", BaseView)

function LevelCardNoviceSaleSlideNode:initCsbNodes()
    LevelCardNoviceSaleSlideNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function LevelCardNoviceSaleSlideNode:initUI()
    LevelCardNoviceSaleSlideNode.super.initUI(self)

    self.m_showData = G_GetMgr(G_REF.CardNoviceSale):getData()
    self:updateSaleInfoUI()
    self:runCsbAction("idle", true)

    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()
end

function LevelCardNoviceSaleSlideNode:getCsbName()
    return "NewUserAlbum_AlbumSale/Icons/Activity_NewUserAlbum_AlbumSale_Slide.csb"
end

function LevelCardNoviceSaleSlideNode:updateSaleInfoUI()
    -- 集卡卡册奖金
    local lbCoins = self:findChild("lb_coin")
    local coins = self.m_showData:getCoins()
    lbCoins:setString(util_formatCoins(coins, 6))
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = lbCoins, alignX = 5}
        }
    )
end

function LevelCardNoviceSaleSlideNode:onUpdateSec()
    local expireAt = self.m_showData:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if not G_GetMgr(G_REF.CardNoviceSale):isSaleRunning() then
        self:clearScheduler()
        gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_SALE_HALL_SLIDE)
    end
end

-- 清楚定时器
function LevelCardNoviceSaleSlideNode:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

--点击回调
function LevelCardNoviceSaleSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelCardNoviceSaleSlideNode:clickLayer(name)
    G_GetMgr(G_REF.CardNoviceSale):showSaleLayer()
end

return LevelCardNoviceSaleSlideNode