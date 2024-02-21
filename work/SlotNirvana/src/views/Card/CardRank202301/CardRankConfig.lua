--[[
    大富翁配置文件
]]
local CardRankConfig = {}

-- 排行榜界面
local rank_path = "CardRes/CardRank202301/CardRank/"
CardRankConfig.RankItemUI = rank_path .. "Card_RankItem.csb"
CardRankConfig.RankUI = rank_path .. "Card_Rank.csb"
CardRankConfig.RankHelpUI = rank_path .. "Card_Rank_help.csb"
CardRankConfig.RankHelpCell1 = rank_path .. "Card_Rank_help_1.csb"
CardRankConfig.RankHelpCell2 = rank_path .. "Card_Rank_help_2.csb"
CardRankConfig.RankHelpCellPoints = rank_path .. "Card_Rank_help_points.csb"
CardRankConfig.RankTitleUI = rank_path .. "Card_RankTitle.csb"
CardRankConfig.RankPlayerItemUI = rank_path .. "Card_Rank_item1.csb"
CardRankConfig.RankRewardItemUI = rank_path .. "Card_Rank_item2.csb"
CardRankConfig.RankTimerUI = rank_path .. "Card_RankTime.csb"

CardRankConfig.RankTopThreeCellLuaPath = "views.Card.CardRank202301.CardRankTopThreeCell"
CardRankConfig.RankTopThreeCellCsbPath = rank_path .. "Card_Rank_Top_Item%d.csb"
return CardRankConfig
