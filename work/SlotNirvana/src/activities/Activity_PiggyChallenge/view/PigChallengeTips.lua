-- 小猪挑战宝箱tips

local PigChallengeTips = class("PigChallengeTips", BaseView)

function PigChallengeTips:ctor()
    PigChallengeTips.super.ctor(self)
    self.m_config = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getConfig()
end

function PigChallengeTips:getCsbName()
    return self.m_config.Bubble
end

function PigChallengeTips:initUI(data)
    PigChallengeTips.super.initUI(self, data)
    self:hideTips()
    self:updateUI(data)
end

function PigChallengeTips:initCsbNodes()
    self.im_qipao = self:findChild("im_qipao")
    self.layout_items = self:findChild("layout_items")
    self.node_coins = self:findChild("node_coins")
    self.sp_coin = self:findChild("sp_coin")
    self.lb_coin = self:findChild("lb_coin")
    self.node_items = self:findChild("node_items")
end

function PigChallengeTips:updateUI(data)
    if not data then
        return
    end

    -- 显示金币
    self.coin_list = {}
    if data.coins and tonumber(data.coins) > 0 then
        self.node_coins:setVisible(true)
        self.lb_coin:setString(util_formatCoins(tonumber(data.coins), 9))
        table.insert(self.coin_list, {node = self.sp_coin, alignX = 2})
        table.insert(self.coin_list, {node = self.lb_coin})
    else
        self.node_coins:setVisible(false)
    end

    -- 显示道具 参照原版 这里显示0.8倍大小
    self.item_list = {}
    self.node_items:removeAllChildren()
    if data.items and table.nums(data.items) > 0 then
        local item_width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
        for idx, item_data in ipairs(data.items) do
            local item = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.TOP)
            item:setScale(0.8)
            self.node_items:addChild(item)
            local alignX = 5
            if idx == #data.items then
                alignX = 0
            end
            table.insert(self.item_list, {node = item, size = cc.size(item_width * 0.8, item_width * 0.8), alignX = alignX})
        end
    end

    self:resize()
end

function PigChallengeTips:resize()
    local coin_length = 0
    if self.coin_list and table.nums(self.coin_list) > 0 then
        for _, item in pairs(self.coin_list) do
            local sp_size = item.node:getContentSize()
            local sp_scale = item.node:getScaleX()
            local alignX = item.alignX or 0
            coin_length = coin_length + sp_size.width * sp_scale + alignX
        end
    end

    local item_length = 0
    if self.item_list and table.nums(self.item_list) > 0 then
        for _, item in pairs(self.item_list) do
            local item_size = item.size
            local alignX = item.alignX or 0
            item_length = item_length + item_size.width + alignX
        end
    end

    local bg_size = self.im_qipao:getContentSize()
    local length = math.max(coin_length, item_length)
    local width = length + 50
    self.im_qipao:setContentSize(cc.size(width, bg_size.height))

    util_alignCenter(self.coin_list)
    util_alignCenter(self.item_list)
end

function PigChallengeTips:showTips()
    self:setVisible(true)
end

function PigChallengeTips:hideTips()
    self:setVisible(false)
end

return PigChallengeTips
