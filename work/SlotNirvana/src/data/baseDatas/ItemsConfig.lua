local ShopItem = util_require("data.baseDatas.ShopItem")
local ItemsConfig = class("ItemsConfig")
ItemsConfig.dropTickets = nil
--掉落折扣券
ItemsConfig.commonTickets = nil --折扣券

function ItemsConfig:ctor()
end
--[[
    @desc:
    author:{author}
    time:2020-09-15 15:47:13
    --@data: 背包信息
    @return:
]]
function ItemsConfig:parseData(data)
    if data then
        if data.tickets then
            self.commonTickets = {}
            for i = 1, #data.tickets do
                local item = self:createShopItem(data.tickets[i])
                self.commonTickets[#self.commonTickets + 1] = item
            end
            G_GetMgr(G_REF.Inbox):getDataMessage(nil, nil, true)
        end
    end
end
--[[
    @desc:
    author:{author}
    time:2020-09-15 15:47:04
    --@data: 掉落信息
    @return:
]]
function ItemsConfig:parseDropsData(data)
    if data then
        if data.tickets then
            self.dropTickets = {}
            for i = 1, #data.tickets do
                local item = self:createShopItem(data.tickets[i])
                self.dropTickets[#self.dropTickets + 1] = item
            end
        end
    end
end

function ItemsConfig:createShopItem(data)
    local item = ShopItem:create()
    item:parseData(data)
    return item
end

function ItemsConfig:getCommonTicketList()
    if not self.commonTickets then
        self.commonTickets = {}
    end
    --剔除过期折扣券
    for i = #self.commonTickets, 1, -1 do
        if not self.commonTickets[i]:checkEffective() then
            table.remove(self.commonTickets, i)
        end
    end
    return self.commonTickets
end
--获取道具折扣
function ItemsConfig:getCommonTicket(id)
    if not self.commonTickets then
        self.commonTickets = {}
    end
    for i = 1, #self.commonTickets do
        if self.commonTickets[i].p_id == id then
            return self.commonTickets[i]
        end
    end
    return nil
end
--获取道具折扣值
function ItemsConfig:getCommonTicketDiscount(id)
    local item = self:getCommonTicket(id)
    if item and item:checkEffective() then
        return item.p_num
    end
    return nil
end

return ItemsConfig
