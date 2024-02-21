-- 活动促销配置
-- FIX IOS 139
local ActivityPromotionConfig = class("ActivityPromotionConfig")

-- 活动配置
ActivityPromotionConfig.config = {
    [ACTIVITY_REF.DinnerLand] = {
        ["promotion_ref"] = ACTIVITY_REF.DinnerLandSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.DINNERLAND_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "ChefSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.Word] = {
        ["promotion_ref"] = ACTIVITY_REF.WordSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.WORD_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "Word" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.Blast] = {
        ["promotion_ref"] = ACTIVITY_REF.BlastSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.BLAST_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "BlastSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.CoinPusher] = {
        ["promotion_ref"] = ACTIVITY_REF.CoinPusherSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.COINPUSHER_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "CoinPusherSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.RichMan] = {
        ["promotion_ref"] = ACTIVITY_REF.RichManSale, -- 促销活动引用类型
        ["promotion_type"] = ACTIVITY_TYPE.RICHMAIN, -- 促销活动类型
        ["buy_type"] = BUY_TYPE.RICHMAN_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "RichManSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.DiningRoom] = {
        ["promotion_ref"] = ACTIVITY_REF.DiningRoomSale, -- 促销活动引用类型
        ["promotion_type"] = ACTIVITY_TYPE.DININGROOM, -- 促销活动类型
        ["buy_type"] = BUY_TYPE.DININGROOM_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "DiningRoomSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.Redecor] = {
        ["promotion_ref"] = ACTIVITY_REF.RedecorSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.REDECOR_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "RedecorateSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.Poker] = {
        ["promotion_ref"] = ACTIVITY_REF.PokerSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.VIDEO_POKER_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "PokerSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.WorldTrip] = {
        ["promotion_ref"] = ACTIVITY_REF.WorldTripSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.WORLDTRIP_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "WorldTripSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.NewCoinPusher] = {
        ["promotion_ref"] = ACTIVITY_REF.NewCoinPusherSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.NEW_COINPUSHER_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "NewCoinPusherSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.PipeConnect] = {
        ["promotion_ref"] = ACTIVITY_REF.PipeConnectSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.PIPECONNECT_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "PipeConnectSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.OutsideCave] = {
        ["promotion_ref"] = ACTIVITY_REF.OutsideCaveSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.OUTSIDECAVE_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "OutsideCaveSale" -- 日志用 购买商品标记
    },
    [ACTIVITY_REF.EgyptCoinPusher] = {
        ["promotion_ref"] = ACTIVITY_REF.EgyptCoinPusherSale, -- 促销活动引用类型
        ["buy_type"] = BUY_TYPE.EGYPT_COINPUSHER_SALE, -- 活动购买类型
        ["items_num"] = 3, -- 活动促销有几个档位
        ["purchaseNameTitle"] = "CoinPusherSale" -- 日志用 购买商品标记
    }
}

return ActivityPromotionConfig
