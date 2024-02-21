--[[
    第三方付费 付费奖励
]]
local InboxItem_AppChargePay = class("InboxItem_AppChargePay", util_require("views.inbox.item.InboxItem_baseReward"))

-- function InboxItem_AppChargePay:initDatas(_data, _removeMySelf)
--     InboxItem_AppChargePay.super.initDatas(self, _data, _removeMySelf)
-- end


function InboxItem_AppChargePay:initData()
    InboxItem_AppChargePay.super.initData(self)
    local productId = self.m_mailData.productId
    if not productId then
        return
    end
    self.m_isMerge = false
    local productInfo = G_GetMgr(G_REF.AppCharge):getProductById(productId)
    self.m_items = productInfo:getItems() or {}
    self.m_coins:setNum(productInfo:getCoins())
    local buk = productInfo:getBuckNum()
    if buk and buk ~= "" and buk ~= "0" then
        self.m_rawardBuckNum = tonumber(buk)
    end
end

function InboxItem_AppChargePay:initView()
    InboxItem_AppChargePay.super.initView(self)
    self:setButtonLabelContent("btn_inbox", "SEE MORE")
end

function InboxItem_AppChargePay:getCsbName()
    return "InBox/InboxItem_exclusivestore_goods.csb"
end

-- 描述说明
function InboxItem_AppChargePay:getDescStr()
    return "EXCLUSIVE STORE"
end

-- -- 如果有掉卡，在这里设置来源
-- function InboxItem_AppChargePay:getCardSource()
--     return {"Zombie Onslaught"}
-- end

function InboxItem_AppChargePay:collectBonus()
    local productId = self.m_mailData.productId
    if not productId then
        return
    end
    G_GetMgr(G_REF.AppCharge):showCollectLayer(productId)
end

return  InboxItem_AppChargePay