--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-08 18:03:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-09 15:22:28
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/controller/TomorrowGiftMgr.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:08
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:21:40
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/controller/TomorrowGiftMgr.lua
Description: 次日礼物 mgr
--]]
local TomorrowGiftMgr = class("TomorrowGiftMgr", BaseGameControl)
local TomorrowGiftConfig = util_require("GameModule.TomorrowGift.config.TomorrowGiftConfig")

function TomorrowGiftMgr:ctor()
    TomorrowGiftMgr.super.ctor(self)

    self:setRefName(G_REF.TomorrowGift)
    self:setDataModule("GameModule.TomorrowGift.model.TomorrowGiftData")
end

-- 获取网络 obj
function TomorrowGiftMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local ActNoviceTrailNet = util_require("GameModule.TomorrowGift.net.TomorrowGiftNet")
    self.m_net = ActNoviceTrailNet:getInstance()
    return self.m_net
end

function TomorrowGiftMgr:getEntryModule()
    return "GameModule.TomorrowGift.views.TomorrowGiftEntryNode"
end

function TomorrowGiftMgr:checkCanPopOpenLayer()
    if not self:isCanShowLayer() then
        return false
    end

    local data = self:getRunningData()
    return data:getSpinTimes() == 1
end

function TomorrowGiftMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByName("TomorrowGiftMainLayer") then
        return
    end

    local view = util_createView("GameModule.TomorrowGift.views.TomorrowGiftMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function TomorrowGiftMgr:updateSpinGiftData(_data)
    if type(_data) ~= "table" then
        return
    end

    local data = self:getData()
    if not data then
        return
    end

    data:updateSpinGiftData(_data)
    gLobalNoticManager:postNotification(TomorrowGiftConfig.EVENT_NAME.NOTICE_PLAY_TOMORROW_GIFT_SPIN_COUNT_ADD_ANI)
end

function TomorrowGiftMgr:sendCollectReq()
    self:getNetObj():sendCollectReq()
end

return TomorrowGiftMgr