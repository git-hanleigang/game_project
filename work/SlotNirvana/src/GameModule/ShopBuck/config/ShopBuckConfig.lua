--[[
]]
GD.ShopBuckConfig = {}

ShopBuckConfig.ItemIcon = "Buck"

-- 默认与左上角的距离 横版
ShopBuckConfig.TOP_POS_H = {x = 235, y = 65}
-- 默认与左上角的距离 竖版
ShopBuckConfig.TOP_POS_V = {x = 150, y = 56}

-- 使用代币进行付费
-- Action数据协议
ProtoConfig.USE_BUCK_PURCHASE = {
    protoType = "USE_BUCK_PURCHASE",
    sign = "TOKEN",
    url = "/v1/game/purchase/buck",
    request = GameProto_pb.BuckPurchaseRequest,
    response = GameProto_pb.PurchaseResponseV2 
}

NetType.ShopBuck = "ShopBuck"
NetLuaModule.ShopBuck = "GameModule.ShopBuck.net.ShopBuckNet"

-- 购买代币
ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS = "NOTIFY_PURCHASE_BUCK_SUCCESS"

-- 代币商城主界面的余额条层级改变
ViewEventType.NOTIFY_BUCKSHOP_UP_LABEL = "NOTIFY_BUCKSHOP_UP_LABEL"
ViewEventType.NOTIFY_BUCKSHOP_RESET_LABEL = "NOTIFY_BUCKSHOP_RESET_LABEL"

-- 代币商城金币滚动
ViewEventType.NOTIFY_BUCKSHOP_FRESH_LABEL = "NOTIFY_BUCKSHOP_FRESH_LABEL"
-- 代币商城金币刷新成最终值
ViewEventType.NOTIFY_BUCKSHOP_UPDATE_LABEL = "NOTIFY_BUCKSHOP_UPDATE_LABEL"

-- 是否使用 BUCK_BUY_TYPE 过滤的开关
ShopBuckConfig.SWITCH = true

-- 可以使用代币的付费类型列表
ShopBuckConfig.BUCK_BUY_TYPE = {
    [BUY_TYPE.STORE_TYPE] = true, -- 金币商城
    [BUY_TYPE.GEM_TYPE] = true, -- 钻石商城
    [BUY_TYPE.LUCKY_SPIN_TYPE] = true, -- 普通luckyspin
    [BUY_TYPE.LUCKY_SPINV2_TYPE] = true, -- 高级luckyspin
    [BUY_TYPE.TRIPLEXPASS_PASSTICKET] = true,
    [BUY_TYPE.TRIPLEXPASS_LEVELSTORE] = true,
    [BUY_TYPE.TRIPLEXPASS_PASSTICKET_NOVICE] = true,
    [BUY_TYPE.TRIPLEXPASS_LEVELSTORE_NOVICE] = true,
    [BUY_TYPE.QUEST_PASS] = true,
    [BUY_TYPE.CHALLENGEPASS_UNLOCK] = true,
    [BUY_TYPE.TopSale] = true,
    [BUY_TYPE.HolidayNewChallengePass] = true,
    [BUY_TYPE.StoreHotSale] = true,
    [BUY_TYPE.PERL_LINK] = true,
    [BUY_TYPE.PERL_NEW_LINK] = true,
    [BUY_TYPE.QUEST_SKIPSALE] = true,
    [BUY_TYPE.QUEST_SKIPSALE_PlanB] = true,
    [BUY_TYPE.MINI_GAME_CASHMONEY] = true,
    [BUY_TYPE.BROKENSALEV2] = true, -- 付费cell、打包
    [BUY_TYPE.CASHBONUS_TYPE_NEW] = true,
    [BUY_TYPE.BLAST_SALE] = true,
    [BUY_TYPE.NEWBLAST_SALE] = true,
    [BUY_TYPE.PIPECONNECT_SALE] = true,
    [BUY_TYPE.PIPECONNECT_SPECIAL_SALE] = true,
    [BUY_TYPE.OUTSIDECAVE_SALE] = true,
    [BUY_TYPE.OUTSIDECAVE_SPECIAL_SALE] = true,
    [BUY_TYPE.EGYPT_COINPUSHER_SALE] = true,
    [BUY_TYPE.EGYPT_COINPUSHER_PACK_SALE] = true,
    [BUY_TYPE.FUNCTION_SALE_PASS] = true,
    [BUY_TYPE.SPECIALSALE] = true,
    [BUY_TYPE.NOCOINSSPECIALSALE] = true, -- 特殊：没钱促销，只有逻辑
    [BUY_TYPE.PIGGYBANK_TYPE] = true,
    [BUY_TYPE.PIG_CHIP] = true,
    [BUY_TYPE.PIG_GEM] = true,
    [BUY_TYPE.PIG_TRIO_SALE] = true,
    [BUY_TYPE.HIGH_MERGE_PURCHASE_STORE] = true,
    [BUY_TYPE.MONTHLY_CARD] = true,
    [BUY_TYPE.FLOWER] = true,
}