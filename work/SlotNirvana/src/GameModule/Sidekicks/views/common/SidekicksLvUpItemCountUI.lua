--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-15 17:00:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-15 17:01:27
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/season/season_1/message/SidekicksLvUpItemCountUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksLvUpItemCountUI = class("SidekicksLvUpItemCountUI", BaseView)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")

function SidekicksLvUpItemCountUI:initDatas(_seasonIdx, _mainLayer)
    SidekicksLvUpItemCountUI.super.initDatas(self)

    self._seasonIdx = _seasonIdx
    self._mainLayer = _mainLayer
    self._data = G_GetMgr(G_REF.Sidekicks):getData()
    -- self._newSeasonIdx = self._data:getNewSeasonIdx()
end

function SidekicksLvUpItemCountUI:getCsbName()
    return string.format("Sidekicks_%s/csd/message/Sidekicks_Message_bag_left.csb", self._seasonIdx)
end

function SidekicksLvUpItemCountUI:initUI()
    SidekicksLvUpItemCountUI.super.initUI(self)
    
    self:updateUI()
end

function SidekicksLvUpItemCountUI:updateUI()
    -- 道具信息
    self:updateItemCount()
    -- 道具图标
    self:updateItemIconUI()
end

-- 道具信息
function SidekicksLvUpItemCountUI:updateItemCount()
    local lbCount = self:findChild("lb_bag_num")
    local count = self._data:getLvUpItemCount()
    lbCount:setString(util_formatMoneyStr(count))
    util_scaleCoinLabGameLayerFromBgWidth(lbCount, 120, 1)
end
-- 道具图标
function SidekicksLvUpItemCountUI:updateItemIconUI()

end

function SidekicksLvUpItemCountUI:onEnter()
    SidekicksLvUpItemCountUI.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self, "updateUI", SidekicksConfig.EVENT_NAME.NOTICE_UPDATE_SIDEKICKS_DATE) -- 宠物数据更新
end

function SidekicksLvUpItemCountUI:getLvUpActPosW()
    local refNode = self:findChild("sp_bag_item")
    return refNode:convertToWorldSpaceAR(cc.p(0, 0))
end

function SidekicksLvUpItemCountUI:clickFunc(_sender)
    if self._mainLayer:getLvUpActing() then
        return
    end
    
    local name = _sender:getName()
    if name == "btn_more" then
        G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 6})
    end
end

return SidekicksLvUpItemCountUI