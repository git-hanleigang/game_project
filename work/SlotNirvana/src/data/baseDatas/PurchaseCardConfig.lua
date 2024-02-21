
local PurchaseCardConfig = class("PurchaseCardConfig")
PurchaseCardConfig.p_productId = nil        --支付id
PurchaseCardConfig.p_price = nil            --价格
PurchaseCardConfig.p_itemId = nil           --道具id
PurchaseCardConfig.p_cards = nil            --卡牌数量
PurchaseCardConfig.p_maxStar = nil          --最大星级卡牌
PurchaseCardConfig.p_maxStarCards = nil     --最大星级卡牌数量
PurchaseCardConfig.p_vipPoints = nil        --vip点数
PurchaseCardConfig.p_clubPoints = nil       --高倍场点数
function PurchaseCardConfig:ctor()
    
end

function PurchaseCardConfig:parseData(data)
    self.p_productId = data.productId           --支付id
    self.p_price = data.price                   --价格
    self.p_itemId = data.itemId                 --道具id
    self.p_cards = data.cards                   --卡牌数量
    self.p_maxStar = data.maxStar               --最大星级卡牌
    self.p_maxStarCards = data.maxStarCards     --最大星级卡牌数量
    self.p_vipPoints = data.vipPoints           --vip点数
    self.p_clubPoints = data.clubPoints         --高倍场点数
end

return  PurchaseCardConfig