--[[
    
]]

local PrizeGameConfig = {}

PrizeGameConfig.notify_prize_game_buy = "prize_game_buy" -- 充值抽奖池 购买
PrizeGameConfig.notify_prize_game_collect = "prize_game_collect" -- 充值抽奖池 领奖
PrizeGameConfig.notify_prize_game_refresh = "prize_game_refresh" -- 充值抽奖池 刷新奖池和中奖记录
PrizeGameConfig.notify_prize_game_collect_layer_close = "notify_prize_game_collect_layer_close"

PrizeGameConfig.buy_type = "PrizeGameSale"

PrizeGameConfig.net_type_collect = 439 -- 充值抽奖领奖
PrizeGameConfig.net_type_refresh = 440 -- 充值抽奖刷新奖池和中奖记录

return PrizeGameConfig