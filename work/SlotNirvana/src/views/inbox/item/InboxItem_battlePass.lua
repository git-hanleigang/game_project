--[[
    battlepass 一键领取
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_battlePass = class("InboxItem_battlePass", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_battlePass:getCsbName()
    return "InBox/InboxItem_BattlePass.csb"
end

function InboxItem_battlePass:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

-- 领取成功
function InboxItem_battlePass:gainRewardSuccess()
    if globalDynamicDLControl:checkDownloading("Activity_BattlePass") then
        release_print("---- click battlePass mail, downloading Activity_BattlePass ----")
        -- 资源没有时没有弹出结算界面，所以也不弹掉落界面，清除掉落缓存
        CardSysManager:clearDropCards("GLORY PASS")
        return
    end
    local _rewardData = {}
    if self.m_mailData.awards ~= nil then
        if self.m_mailData.awards.coins and tonumber(self.m_mailData.awards.coins) > 0 then
            _rewardData.coins = tonumber(self.m_mailData.awards.coins)
        end
        if self.m_mailData.awards.items ~= nil then
            _rewardData.items = {}
            for i=1,#self.m_mailData.awards.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(self.m_mailData.awards.items[i], true)
               _rewardData.items[i] = shopItem
            end
        end
    end
    if next(_rewardData) ~= nil  then
        local view = util_createView("Activity.BattlePassCode.BattlePassRewardLayer", _rewardData)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

return  InboxItem_battlePass