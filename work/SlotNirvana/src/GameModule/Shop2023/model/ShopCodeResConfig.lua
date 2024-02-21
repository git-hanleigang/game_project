
local ShopCodeResConfig =  {}

local CODE_PATH = "GameModule/Shop2023/views/"
local RES_PATH = "Shop2023_Res/"

ShopCodeResConfig.type =
{
    COIN = 1,
    GEMS = 2,
    BOOST = 3,
    RECOMMEND = 4,
    HOT = 5,
    PET = 6
    
    --.....
}
-- base下的代码文件路径
ShopCodeResConfig.code = 
{
    -- shop base --
    ShopBaseItemNum            = CODE_PATH.."ShopBase/ShopBaseItemNum",     -- 新版商城 base num基础节点
    ShopBaseItemCellNode       = CODE_PATH.."ShopBase/ShopBaseItemCellNode",-- 新版商城 base cell滑动基础节点

    -- shop mainlayer --
    MainLayer                  = CODE_PATH.."ShopMainLayer",               -- 新版商城 主界面
    FreeCoinsNode              = CODE_PATH.."ShopFreeCoinsNode",           -- 新版商城 每日免费金币
    RapidPositionBtnNode       = CODE_PATH.."ShopRapidPositionBtnNode",    -- 新版商城 下方按钮
    RapidLeftPositionBtnNode   = CODE_PATH.."ShopRapidLeftPositionBtnNode",    -- 新版商城 左方按钮
    RecommendedPositionNode    = CODE_PATH.."ShopRecommendedPositionNode", -- 新版商城 推荐位node
    VipNode                    = CODE_PATH.."ShopVipNode",                 -- 新版商城 vip 节点
    BuyTipItemNode             = CODE_PATH.."ShopBuyTipItemNode",                 -- 新版商城 vip 节点
    TopAccountNode             = CODE_PATH.."ShopTopAccount",              -- 新版商城 金币、gems 节点
    TopBuckNode                = CODE_PATH.."ShopTopBuck",              -- 新版商城 金币、gems 节点
    ShopTopTicketUI            = CODE_PATH.."ShopTopTicketUI",              -- 新版商城 商城优惠劵 节点
    BaseShopTopTicketUI        = CODE_PATH.."BaseShopTopTicketUI",              -- 新版商城 商城优惠劵 节点
    RecommendedTimeNode        = CODE_PATH.."ShopRecommendedTimeNode", -- 新版商城 推荐位node
    RecommendedBgNode          = CODE_PATH.."ShopRecommendedBgNode", -- 新版商城 推荐位node
    ScratchCardsNode           = CODE_PATH.."ShopScratchCardsNode", -- 新版商城 刮刮卡node
    PromomodeNode              = CODE_PATH.."ShopPromomodeNode",    -- 新版商城 折扣开关
    -- shop item --
    ItemCellFrameLine          = CODE_PATH.."ShopItem/ShopItemCellFrameLine",  -- 新版商城 cell 中间分割线
    ItemCellNodeCoin           = CODE_PATH.."ShopItem/ShopItemCellNodeCoin",       -- 新版商城 cell模块
    ItemCellNodeGems           = CODE_PATH.."ShopItem/ShopItemCellNodeGems",       -- 新版商城 cell模块
    ItemCellNodeHot            = CODE_PATH.."ShopItem/ShopItemCellNodeHotSale",       -- 新版商城 cell模块
    ItemCellNodePet           = CODE_PATH.."ShopItem/ShopItemCellNodePet",       -- 新版商城 cell模块
    ItemCellNodeMonthlyCard    = CODE_PATH.."ShopItem/ShopItemCellNodeMonthlyCard",       -- 新版商城 cell模块
    ItemCellNodeScratchCard    = CODE_PATH.."ShopItem/ShopItemCellNodeScratchCard",       -- 新版商城 cell模块 刮刮卡
    
    
    ItemIconNode               = CODE_PATH.."ShopItem/ShopItemIconNode",       -- 新版商城 cell上的图标
    ItemCoinNumNode            = CODE_PATH.."ShopItem/ShopItemCoinNumNode",    -- 新版商城 cell金币数字
    ItemGemsNumNode            = CODE_PATH.."ShopItem/ShopItemGemsNumNode",    -- 新版商城 cell第二货币数字
    ItemReCommendNumNode       = CODE_PATH.."ShopItem/ShopItemRecommendNumNode",    -- 新版商城 cell 推荐位上的金币数值
    ItemBenefitBoardLayer      = CODE_PATH.."ShopItem/ShopItemBenefitBoardLayer",            -- 新版商城 cell奖励道具板
    ItemBenefitBoardCellNode   = CODE_PATH.."ShopItem/ShopItemBenefitBoardCellNode",        -- 新版商城 cell奖励道具
    ItemTicketNode             = CODE_PATH.."ShopItem/ShopItemTicketNode",        -- 新版商城 cell奖励道具

    ItemPetInfoNode       = CODE_PATH.."ShopItem/ShopItemPetInfoNode",    -- 新版商城 cell 上的宠物说明
    ItemPetLevelNode       = CODE_PATH.."ShopItem/ShopItemPetLevelNode",    -- 新版商城 cell 上的宠物荣誉等级
    ItemPetLockNode       = CODE_PATH.."ShopItem/ShopItemPetLockNode",

    ItemExtraNode              = CODE_PATH.."ShopItem/ShopItemExtraNode",        -- 新版商城 额外奖励

    -- info ---
    InfoLayer                  = CODE_PATH .. "ShopRulesLayer",     -- 说明界面  

    ShopBenefitLayer           = CODE_PATH .. "ShopBenefitLayer",     -- 权益界面  
}
-- base下的资源路径
ShopCodeResConfig.res = 
{
    ------------------------------------ 主目录 部分 ------------------------------------
    ---- benefitBoard
    ItemBenefitBoardCell   = RES_PATH.."csd/benefitBoard/Shop2023_benefitBoard_cell.csb",
    ItemBenefitBoard       = RES_PATH.."csd/benefitBoard/Shop2023_benefitBoard.csb",
    
    ---- itemCell
    ItemCell               = RES_PATH.."csd/itemCell/Shop2023_cell.csb",
    ItemCell_Vertical      = RES_PATH.."csd/itemCell/Shop2023_cell_vertical.csb",
    GemLineNode            = RES_PATH.."csd/itemCell/Shop2023_gemLine.csb",
    GemLineNode_Vertical   = RES_PATH.."csd/itemCell/Shop2023_gemLine_vertical.csb",
    ItemIcon_Coin          = RES_PATH.."csd/itemCell/Shop2023_itemIcon_Coin_",
    ItemIcon_Gems          = RES_PATH.."csd/itemCell/Shop2023_itemIcon_Gems_",
    ItemIcon_Hot           = RES_PATH.."csd/Recommended/",
    ItemIcon_Pet           = RES_PATH.."csd/itemCell/Shop2023_itemIcon_Pet_",
    ItemNumber             = RES_PATH.."csd/itemCell/Shop2023_number.csb",
    ItemNumber_special             = RES_PATH.."csd/itemCell/Shop2023_number_special.csb",
    ItemIcon_Boost         = RES_PATH.."csd/itemCell/Shop2023_boosted.csb",

    ItemCell_BtnBuy         = RES_PATH.."csd/itemBtnBuy/Shop2023_itemBuy.csb",

    ItemCell_Big           = RES_PATH.."csd/itemCell/Shop2023_cell_big.csb",
    ItemCell_Big_Vertical      = RES_PATH.."csd/itemCell/Shop2023_cell_big_vertical.csb",

    ItemCell_Golden           = RES_PATH.."csd/itemCell/Shop2023_cell_special.csb",
    ItemCell_Golden_Vertical      = RES_PATH.."csd/itemCell/Shop2023_cell_special_vertical.csb",

    ItemCell_PetGolden           = RES_PATH.."csd/itemCell/Shop2023_cell_pet_gold.csb",
    ItemCell_PetGolden_Vertical      = RES_PATH.."csd/itemCell/Shop2023_cell_pet_gold_vertical.csb",

    ItemCell_MonthlyCard          = RES_PATH.."csd/Monthly/Shop2023_Monthly.csb",
    ItemCell_MonthlyCard_Vertical      = RES_PATH.."csd/Monthly/Shop2023_Monthly_vertical.csb",

    ItemCell_ScratchCard          = RES_PATH.."csd/ScratchCard/Shop2023_ScratchCard.csb",
    ItemCell_ScratchCard_Vertical      = RES_PATH.."csd/ScratchCard/Shop2023_ScratchCard_vertical.csb",
    ItemCell_ScratchCard_Spine      = RES_PATH.."ui/ui_ScratchCard/spine/Shop2023_ScratchCard",

    ItemPetCell_Info               = RES_PATH.."csd/itemCell/Shop2023_pet_info.csb",
    ItemPetCell_LOCK_Vertical      = RES_PATH.."csd/itemCell/shop2023_pet_unlock_0.csb",
    ItemPetCell_Level               = RES_PATH.."csd/itemCell/Shop2023_pet_level.csb",
    ItemPetCell_LOCK               = RES_PATH.."csd/itemCell/shop2023_pet_unlock.csb",

    ItemExtraNode                  = RES_PATH.."csd/itemCell/Shop2023_extra.csb",
    
    ---- bottomUi
    FreeCoinsNode              = RES_PATH.."csd/bottomUi/Shop2023_freeCoins.csb",
    RapidPositionBtn           = RES_PATH.."csd/bottomUi/Shop2023_rapidPositionBtn.csb",
    RapidPositionBtn_Vertical  = RES_PATH.."csd/bottomUi/Shop2023_rapidPositionBtn_vertical.csb",


    RapidLeftPositionBtn           = RES_PATH.."csd/bottomUi/Shop2023_leftYeqian.csb",
    RapidLeftPositionBtn_Vertical  = RES_PATH.."csd/bottomUi/Shop2023_leftYeqian_vertical.csb",
    
    ---- buyTip
    ShopBuyTipLayer            = RES_PATH.."csd/buyTip/Shop2023_buyTip.csb",
    ShopBuyTipLayer_Vertical   = RES_PATH.."csd/buyTip/Shop2023_buyTip_vertical.csb",
    ShopBuyTipItemNode         = RES_PATH.."csd/buyTip/Shop2023_buyTip_ItemNode.csb",
    
    ---- mainLayer
    ShopMainLayer                  = RES_PATH.."csd/mainLayer/Shop2023_mainLayer.csb",
    ShopMainLayer_Vertical         = RES_PATH.."csd/mainLayer/Shop2023_mainLayer_vertical.csb",
    RecommendedPosition            = RES_PATH.."csd/mainLayer/Shop2023_recommendedPosition.csb",
    RecommendedPosition_Vertical   = RES_PATH.."csd/mainLayer/Shop2023_recommendedPosition_vertical.csb",
    RecommendedTimeNode            = RES_PATH.."csd/mainLayer/Shop2023_recommendedTimeNode.csb",
    
    ---- topUi
    VipNode                    = RES_PATH.."csd/topUi/Shop2023_vip.csb",
    AccountNodeH               = RES_PATH.."csd/topUi/Shop2023_accountH.csb",
    AccountNodeV               = RES_PATH.."csd/topUi/Shop2023_accountV.csb",
    BuckNodeH                  = RES_PATH.."csd/topUi/Shop2023_bucksH.csb",
    BuckNodeV                  = RES_PATH.."csd/topUi/Shop2023_bucksV.csb",
    PromomodeH                 = RES_PATH.."csd/topUi/Shop2023_promomodeH.csb",    -- 新版商城 折扣开关
    PromomodeV                 = RES_PATH.."csd/topUi/Shop2023_promomodeV.csb",    -- 新版商城 折扣开关
    CoinsTicketNode            = RES_PATH.."csd/topUi/Shop2023_top_coinCoupon.csb",    -- 新版商城 优惠劵资源 金币
    CoinsTicketNode_p          = RES_PATH.."csd/topUi/Shop2023_top_coinCoupon_vertical.csb",    -- 新版商城 优惠劵资源 金币
    GemsTicketNode             = RES_PATH.."csd/topUi/Shop2023_top_gemCoupon.csb",    -- 新版商城 优惠劵资源 钻石
    GemsTicketNode_p           = RES_PATH.."csd/topUi/Shop2023_top_gemCoupon_vertical.csb",    -- 新版商城 优惠劵资源 钻石
    
    --- 推荐位目录
    RecommendBgDefaultNode        = "Shop_rec_coinDefault.csb", -- 默认csb

    -- info -- 
    InfoNode                   = RES_PATH .. "csd/mainLayer/Shop2023_rules.csb",     -- 说明界面  
    InfoNode_Vertical          = RES_PATH .. "csd/mainLayer/Shop2023_rules_vertical.csb",     -- 说明界面  

    -- 金币膨胀，老资源路径进入配置中
    CarnivalLayer = RES_PATH .. "csd/mainLayer/Shop2023_bigbangLayer.csb",

    CoinLizi = RES_PATH .. "csd/mainLayer/Shop2023_coinlizi.csb",

    --音效相关
    Sound_carnival_up = RES_PATH .. "sound/sound_carnival_up.mp3", -- 嘉年华会
    Sound_carnival_over = RES_PATH .. "sound/sound_carnival_over.mp3",
    Sound_carnival_baoza = RES_PATH .. "sound/sound_carnival_baoza.mp3",

    Sound_promomode = RES_PATH .. "sound/shop_promomode.mp3",

}

return ShopCodeResConfig
