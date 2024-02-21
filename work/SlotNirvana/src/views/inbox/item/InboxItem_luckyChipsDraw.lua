---
--island
--2019年3月14日
--InboxItem_luckyChipsDraw.lua
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_luckyChipsDraw = class("InboxItem_luckyChipsDraw", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_luckyChipsDraw:getCsbName()
    local csbName = "InBox/InboxItem_LuckChipsDraw2.csb" --默认皮肤
    return csbName
end

-- 描述说明
function InboxItem_luckyChipsDraw:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_luckyChipsDraw:initData()
    InboxItem_luckyChipsDraw.super.initData(self)
    local num = 0
    local awardsItem = self.m_mailData.awards.items
    if awardsItem ~= nil then
        local extraPropList = {}
        for k, v in ipairs(awardsItem) do
            local cell = ShopItem:create()
            cell:parseData(v, true)
            num = num + cell.p_num
        end
    else
        num = 1
    end
    self.m_tickNum = num
end

function InboxItem_luckyChipsDraw:showTick()
    local strNum = string.format("+%d TICKETS", self.m_tickNum)
    local mgr = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw)
    local cfg = mgr:getConfig()
    mgr:showLuckyChipsDrawDialog(
        "LuckyChipsDrawReward",
        cfg.csbPath .. "LuckChipsDrawBuy.csb",
        true,
        function(name)
            if not tolua.isnull(self) and self.showLuckyChipsDraw then
                self:showLuckyChipsDraw()
            end
        end,
        {
            m_lb_num = strNum
        }
    )
end

--弹出
function InboxItem_luckyChipsDraw:showLuckyChipsDraw(btnName)
    if btnName and btnName == "btn_open" then
        local luckyChipsUI = nil
        local luckyChipsDrawMgr = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw)
        if luckyChipsDrawMgr and luckyChipsDrawMgr.showMainLayer then
            luckyChipsUI = luckyChipsDrawMgr:showMainLayer()
        end
        if luckyChipsUI then
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "InboxItem_luckyChipsDraw")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
        end
    else
        if self.removeSelfItem then
            self:removeSelfItem()
        end
    end
end

function InboxItem_luckyChipsDraw:collectMailSuccess()
    local drawData = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw):getRunningData()
    if drawData == nil or drawData:isRunning() == false then
        InboxItem_luckyChipsDraw.super.collectMailSuccess(self)
    else
        self:showTick()
    end
end

return  InboxItem_luckyChipsDraw
