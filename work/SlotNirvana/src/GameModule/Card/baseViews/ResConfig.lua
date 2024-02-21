--[[
    集卡系统需要的资源列表
--]]
GD.CardResConfig = {}

-- 进入大厅后动态下载的zip包名
-- ！！！ 注意：isDynamic，只有最新两个赛季是TRUE
CardResConfig.CardResDynamicKey = {
    ["202401"] = "CardsRes202401",
    ["202304"] = "CardsRes202304",
    ["202303"] = "CardsRes202303",
    ["202302"] = "CardsRes202302",
    ["202301"] = "CardsRes202301",
    ["202204"] = "CardsRes202204",
    ["202203"] = "CardsRes202203",
    ["202202"] = "CardsRes202202",
    ["202201"] = "CardsRes202201",
    ["202104"] = "CardsRes202104",
    ["202103"] = "CardsRes202103",
    ["202102"] = "CardsRes202102",
    ["202101"] = "CardsRes202101",
    ["201904"] = "CardsRes201904",
    ["201903"] = "CardsRes201903",
    ["201902"] = "CardsRes201902",
    ["201901"] = "CardsRes201902",
    ["302301"] = "CardsRes302301" -- 新手期集卡
}

CardResConfig.CardPageTabRes = {
    "CardRes/Other/CardTitle_anniu_%s_1.png",
    "CardRes/Other/CardTitle_anniu_%s_2.png",
    "CardRes/Other/CardTitle_anniu_%s_2.png"
}

-- 资源路径管理分为三大类
-- Base：资源路径在CardRes下，直接索引即可
-- Common：资源路径在CardRes/Commonxxxxxx/下
-- Season：资源路径在CardRes/Seasonxxxxxx/下

-- -- 赛季选择面板 --
-- CardResConfig.CardSeasonViewRes     = "CardRes/cash_season_layer.csb"
-- CardResConfig.CardSeasonCellBook2019Res = "CardRes/cash_season_cell_book.csb"
-- CardResConfig.CardSeasonCellBook2020Res = "CardRes/cash_season_cell_book_2020.csb"
-- CardResConfig.CardSeasonCell2019Res = "CardRes/cash_season_cell_2019.csb"
-- CardResConfig.CardSeasonCell2020Res = "CardRes/cash_season_cell_2020.csb"
-- CardResConfig.CardSeasonGrassSpineRes = "CardRes/spine/cash_season_cell_Grass"
-- CardResConfig.CardSeasonTimeRes      = "CardRes/cash_season_layer_time.csb"
-- CardResConfig.CardSeasonTime2020Res      = "CardRes/cash_season_layer_time2020.csb"
-- 拼图章节中用到
CardResConfig.CardSeasonCellPizzleHouseRes = "CardRes/cash_season_cell_pizzlehouse.csb"

CardResConfig.CardMenuNodeRes = "CardRes/cash_menu_more.csb"
CardResConfig.CardMenuWheelNodeRes = "CardRes/cash_menu_wheel.csb"
-- 卡组选择面板 --
CardResConfig.CardAlbumViewRes = "CardRes/cash_album_layer.csb"
CardResConfig.CardAlbumCell2019UnitRes = "CardRes/cash_album_cell_2019.csb"
CardResConfig.CardAlbumCell2020Res = "CardRes/cash_album_cell_2020.csb"
CardResConfig.CardAlbumCell2020WildUnitRes = "CardRes/cash_album_cell_2020_wild_unit.csb"
CardResConfig.CardAlbumCell2020WildEffectRes = "CardRes/cash_album_cell_2020_wild_card.csb"
CardResConfig.CardAlbumCell2020NormalUnitRes = "CardRes/cash_album_cell_2020_normal_unit.csb"
CardResConfig.CardAlbumLinkDownRes = "CardRes/cash_album_layer_linkdown.csb"
CardResConfig.CardAlbumLinkUpRes = "CardRes/cash_album_layer_linkup.csb"

-- 卡组面板    --
CardResConfig.CardClanViewRes = "CardRes/cash_clan_layer.csb"
CardResConfig.CardClanViewCardNodes = "CardRes/cash_clan_cell.csb"
CardResConfig.CardClanViewWildNodeRes = "CardRes/cash_clan_cell_wild.csb"
CardResConfig.CardClanViewWildCardRes = "CardRes/cash_clan_cell_wild_cards.csb"

CardResConfig.CardClanTitle201901Res = "CardRes/cash_clan_title_2019.csb"
CardResConfig.CardClanTitle201902NormalRes = "CardRes/cash_clan_title_2020_normal.csb"
CardResConfig.CardClanTitle201902WildRes = "CardRes/cash_clan_title_2020_wild.csb"

CardResConfig.CardClanCellLinkTipRes = "CardRes/cash_clan_cell_link_tip.csb"

-- 赛季界面，轮盘的提示UI
CardResConfig.CardMenuWheelTipRes = "CardRes/CashCard_tishi.csb"

--轮盘回收
CardResConfig.CardRecoverWheelViewRes = "CardRes/CardLink_wheel.csb"
CardResConfig.CardRecoverWheelBgViewRes = "CardRes/CashCards_wheel_bg.csb"
CardResConfig.CardRecoverWheelBgPrizeEffectRes = "CardRes/CashCards_wheel_prize.csb"

-- 查看普通规则面板 --
CardResConfig.CardCollectRuleRes = "CardRes/CardLink_rule.csb"

-- 查看奖励规则面板 --
CardResConfig.CardPrizeRuleRes = "CardRes/CardLink_prize.csb"
CardResConfig.CardPrizeRuleCellRes = "CardRes/CardLink_rule_tip.csb"

-- Wild小卡片面板 --
CardResConfig.WildCardRes = "CardRes/WildCardRes.csb"
-- Wild大卡片面板 --
CardResConfig.WildBigCardRes = "CardRes/WildCardRes.csb"

-- 大卡牌 界面
CardResConfig.BigCardLayerRes = "CardRes/cash_card_big_layer.csb"

-- 展示需要点击进入Link游戏的Link卡牌 --
CardResConfig.GoToLinkGameCard = "CardRes/cash_card_link_layer.csb"
CardResConfig.LinkMiniCardTipRes = "CardRes/cash_card_link_tip.csb"

-- Link大卡面板弹出的提示界面
CardResConfig.LinkCardTipRes = "CardRes/cash_card_linklong_tip.csb"
--ask send 提示
CardResConfig.LinkCardLongBtnTipRes = "CardRes/cash_card_long_btntip.csb"
-- 卡牌基础面板 --
CardResConfig.CardUnitCsbRes = {
    long = {
        normal = "CardRes/cash_card_nomallong.csb",
        link = "CardRes/cash_card_linklong.csb",
        golden = "CardRes/cash_card_jinlong.csb",
        wild = "CardsBase201902/CardRes/cash_card_wild.csb"
    },
    mini = {
        normal = "CardsBase201902/CardRes/cash_card_nomalmini.csb",
        link = "CardsBase201902/CardRes/cash_card_linkmini.csb",
        golden = "CardsBase201902/CardRes/cash_card_jinmini.csb",
        wild = "CardsBase201902/CardRes/cash_card_wild.csb",
        puzzle = "CardsBase201902/CardRes/cash_card_puzzle.csb"
    }
}
-- 长卡的卡牌描述 --
CardResConfig.LongCardUnitCellRes = "CardRes/cash_card_longcell.csb"

-- 卡牌的右下角提示 数字和new
CardResConfig.CardNumTipRes = "CardRes/cash_card_num.csb"

CardResConfig.CardUnitResPath = "CardRes/ui/"
CardResConfig.CardUnitOtherResPath = "CardRes/Other/"

-- 集卡赛季资源路径
CardResConfig.getCardSeasonFilePath = function(year, season)
    return string.format("CardRes/" .. string.format("ui_%s_%d", year, season))
end

CardResConfig.getCardSeasonBookRes = function()
    return "season/season_book_bg.png", "season/season_book_logo.png"
end
CardResConfig.getCardAlbumRes = function()
    return "album/album_bg.png", "album/album_reward_bg.png"
end

CardResConfig.CARD_LINK_DOWN = "CardsBase201902/CardRes/Other/link_down.png"
CardResConfig.CARD_LINK_UP = "CardsBase201902/CardRes/Other/link_up.png"

-- 卡牌基础面板上星星配置
CardResConfig.CardUnitStarRes = {
    [1] = {"CashCards_start_bg.png"},
    [2] = {
        [1] = "CashCards_start1.png",
        [2] = "CashCards_start2.png",
        [3] = "CashCards_start3.png",
        [4] = "CashCards_start4.png",
        [5] = "CashCards_start5.png"
    }
}

-- 滚动条资源 --
CardResConfig.WildSliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_historyBg.png" -- CashCards_wildtc_tiao.png
CardResConfig.WildSliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_ruleMaker.png" -- CashCards_wildtc_tiao1.png
CardResConfig.AlbumSliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_albumBg.png"
CardResConfig.AlbumSliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_albumMaker.png"
CardResConfig.RuleSliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_ruleBg.png"
CardResConfig.RuleSliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_ruleMaker.png"
CardResConfig.HistorySliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_historyBg.png"
CardResConfig.HistorySliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_ruleMaker.png"
CardResConfig.DropSliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_dropBg.png"
CardResConfig.DropSliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_dropMasker.png"
CardResConfig.CollectionSliderBg = "CardsBase201902/CardRes/Other/CashCards_slider_collectionBg.png"
CardResConfig.CollectionSliderMark = "CardsBase201902/CardRes/Other/CashCards_slider_collectionMarker.png"

CardResConfig.ExchangeSliderBg = "CardRes/%s/img/cash_recover/cash_recover_gaiban/cash_recover_huadongtiao2.png"
CardResConfig.ExchangeSliderMark = "CardRes/%s/img/cash_recover/cash_recover_gaiban/cash_recover_huadongtiao1.png"

--其他资源
CardResConfig.LongDesDianBg = "CardsBase201902/CardRes/Other/CashCards_an_jindu.png"
CardResConfig.LongDesDian = "CardsBase201902/CardRes/Other/CashCards_an_jindu1.png"
CardResConfig.CardHuiBg = "CardsBase201902/CardRes/Other/CashCards_ka_zise.png"
CardResConfig.DropLinkEff = "CardsBase201902/CardRes/Other/CashCards_link_frameEff.png"
CardResConfig.DropGoldEff = "CardsBase201902/CardRes/Other/CashCards_gold_frameEff.png"

--首次进入集卡系统提示特殊提示
CardResConfig.FirstEnterTips = "CardRes/cash_card_firsttip_layer.csb"

-- 那150张图。具体怎么个拼接图片名称的方法
-- y年度/s赛季/group卡组/n卡片
-- 直接用卡片id截取
-- 例如卡片id 19010101  截取前俩个 y20+19/s+01/group+01/n+01+.png
CardResConfig.CardIconPath = "y20%02d/s%02d/group%02d/n%02d.png"
CardResConfig.CardMiniIconPath = "y20%02d/s%02d/group%02d/mini_%02d.png"
-- 新手期集卡icon、logo {CardId:33010101}
CardResConfig.NoviceCardIconPath = "y3023/s%02d/group%02d/n%02d.png"
CardResConfig.getCardIcon = function(CardId, isMini, isNovice)
    local year = string.sub(CardId, 1, 2)
    local season = string.sub(CardId, 3, 4)
    local group = string.sub(CardId, 5, 6)
    local card = string.sub(CardId, 7, 8)
    if isMini then
        return string.format(CardResConfig.CardMiniIconPath, year, season, group, card)
    end
    if isNovice then
        return string.format(CardResConfig.NoviceCardIconPath, season, group, card)
    end
    return string.format(CardResConfig.CardIconPath, year, season, group, card)
end

-- 获得对应赛季黑曜卡的标签
CardResConfig.ObsidianCardTagIconPath = "y20%02d/s%02d/group%02d/obsidianTag%d.png"
CardResConfig.getObsidianCardTagIcon = function(CardId, isHave)
    local year = string.sub(CardId, 1, 2)
    local season = string.sub(CardId, 3, 4)
    local group = string.sub(CardId, 5, 6)
    local flag = isHave and 1 or 0
    return string.format(CardResConfig.ObsidianCardTagIconPath, year, season, group, flag)
end

-- 20190221
CardResConfig.WildCardBgIconPath = "y20%02d/s%02d/group%02d/nbg.png"
CardResConfig.getWildCardBgIcon = function(ClanId)
    local year = string.sub(ClanId, 3, 4)
    local season = string.sub(ClanId, 5, 6)
    local group = string.sub(ClanId, 7, 8)
    return string.format(CardResConfig.WildCardBgIconPath, year, season, group)
end

--link卡 abtest
CardResConfig.getLinkCardTarget = function()
    if globalData.GameConfig.checkOldCardLink and globalData.GameConfig:checkOldCardLink() then
        return "CardsBase201902/CardRes/Other/Cardlink_A.png"
    else
        return "CardsBase201902/CardRes/Other/Cardlink.png"
    end
end
CardResConfig.getLinkCardButton = function(isGrey)
    if isGrey then
        return "CardsBase201902/CardRes/Other/Cardlink_hui.png"
    else
        return "CardsBase201902/CardRes/Other/Cardlink.png"
    end
end
--获得link图标
CardResConfig.getLinkCardIcon = function()
    return "CardsBase201902/CardRes/Other/CashCards_link.png"
end

-- 每一个卡组的logo资源路径
-- y2019/s01/group01/logo_1.png
-- y2019/s01/group01/logocard_1.png
-- clanId： 20190102
CardResConfig.ClanIconPath = "y%02d/s%02d/group%02d/logo_%d.png"
CardResConfig.ClanGreyIconPath = "y%02d/s%02d/group%02d/logocard_%d.png"
CardResConfig.getCardClanIcon = function(clanId, grey)
    local year = string.sub(clanId, 1, 4)
    local season = string.sub(clanId, 5, 6)
    local clanIndex = string.sub(clanId, 7, 8)
    if grey then
        return string.format(CardResConfig.ClanGreyIconPath, year, season, clanIndex, clanIndex)
    else
        return string.format(CardResConfig.ClanIconPath, year, season, clanIndex, clanIndex)
    end
end
-- 获取黑曜卡组的 logo资源
CardResConfig.getObsidianCardClanIcon = function(_clanId)
    local season = string.sub(_clanId, 5, 6)
    return string.format("y2091/s%02d/group01/logo_1.png", season)
end

-- CardResConfig.DyClanIconPath = "CardRes/logo%d%02d/logo_%d.png"
-- CardResConfig.DyClanGreyIconPath = "CardRes/logo%d%02d/logocard_%d.png"
-- CardResConfig.getCardDyClanIcon = function(clanId, grey)
--     local year = string.sub(clanId,1,4)
--     local season = string.sub(clanId,5,6)
--     local clanIndex = string.sub(clanId,7,8)
--     if grey then
--         return string.format(CardResConfig.DyClanGreyIconPath, year, season, clanIndex)
--     else
--         return string.format(CardResConfig.DyClanIconPath, year, season, clanIndex)
--     end
-- end

-- 章节背景资源路径
CardResConfig.ClanBgPath = "y%02d/s%02d/group%02d/zhangjie_%d.png"
CardResConfig.getCardClanBg = function(clanId)
    local year = string.sub(clanId, 1, 4)
    local season = string.sub(clanId, 5, 6)
    local clanIndex = string.sub(clanId, 7, 8)
    return string.format(CardResConfig.ClanBgPath, year, season, clanIndex, clanIndex)
end

CardResConfig.getCardBgRes = function(_cardType, hasCard)
    if _cardType == CardSysConfigs.CardType.normal then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_normal_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_normal_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.golden then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_golden_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_golden_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.link then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_nado_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_nado_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.statue_green then
        -- 这种卡牌没有做未获得的样子
        return "CardsBase201903/CardRes/Other/statueBg_level_1.png"
    elseif _cardType == CardSysConfigs.CardType.statue_blue then
        -- 这种卡牌没有做未获得的样子
        return "CardsBase201903/CardRes/Other/statueBg_level_2.png"
    elseif _cardType == CardSysConfigs.CardType.statue_red then
        -- 这种卡牌没有做未获得的样子
        return "CardsBase201903/CardRes/Other/statueBg_level_3.png"
    elseif _cardType == CardSysConfigs.CardType.quest_new then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_quest_new_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_quest_new_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.obsidian then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_obsidian_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_obsidian_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.quest_magic_red then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_mythic_red_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_mythic_red_0.png"
        end
    elseif _cardType == CardSysConfigs.CardType.quest_magic_purple then
        if hasCard then
            return "CardsBase201903/CardRes/Other/ChipBg_mythic_purple_1.png"
        else
            return "CardsBase201903/CardRes/Other/ChipBg_mythic_purple_0.png"
        end
    end
    return
end

-- 测试面板 --
CardResConfig.TestViewRes = "CardRes/LayerTest.csb"

CardResConfig.SeasonJellyfishSpineRes = "CardsBase201902/CardRes/spine/CashCardsSeasonLayer"
-- 掉落界面的卡包骨骼动画 --
CardResConfig.CardDropPackageSpineRes = "CardsBase201902/CardRes/spine/CardLink_diaoluo_kabao"

-- 卡牌的底板每个章节都不一样 --
CardResConfig.ClanCardNailPath = "CardsBase201902/CardRes/ClanCardBack/card_nail_%s.png"
CardResConfig.ClanCardBigLinePath = "CardsBase201902/CardRes/ClanCardBack/card_bigbg_%s.png"
CardResConfig.ClanCardNormalLinePath = "CardsBase201902/CardRes/ClanCardBack/card_normalbg_%s.png"

-- 集卡掉落引导
CardResConfig.CardDropGuideRes = "CardRes/CashCards_drop_guide.csb"

-- 集卡小游戏界面
CardResConfig.PuzzlePageMainRes = "CardRes/season201904/CashPuzzle/Page_main.csb"
CardResConfig.PuzzlePageTitleRes = "CardRes/season201904/CashPuzzle/Page_title.csb"
CardResConfig.PuzzlePageItemsRes = "CardRes/season201904/CashPuzzle/Page_items.csb"
CardResConfig.PuzzlePageItemsCellRes = "CardRes/season201904/CashPuzzle/Page_items_cell.csb"
CardResConfig.PuzzleGemBuyRes = "CardRes/season201904/CashPuzzle/Game_gem_buy.csb"
CardResConfig.PuzzleGemOutRes = "CardRes/season201904/CashPuzzle/Game_gem_out.csb"

CardResConfig.PuzzlePageCompleteRes = "CardRes/season201904/CashPuzzle/Page_complete.csb"
CardResConfig.PuzzlePageCompleteRewardRes = "CardRes/season201904/CashPuzzle/Page_complete_reward.csb"

CardResConfig.PuzzleGameStartRes = "CardRes/season201904/CashPuzzle/Game_start.csb"
CardResConfig.PuzzleGameMainRes = "CardRes/season201904/CashPuzzle/Game_main.csb"
CardResConfig.PuzzleGameMainBoxRes = "CardRes/season201904/CashPuzzle/Game_main_box.csb"
CardResConfig.PuzzleGameMainBoxAwardRes = "CardRes/season201904/CashPuzzle/Game_main_box_award.csb"
CardResConfig.PuzzleGameMainBoxFlyRes = "CardRes/season201904/CashPuzzle/Game_main_box_tuowei.csb"
CardResConfig.PuzzleGameMainGemRes = "CardRes/season201904/CashPuzzle/Game_main_gem.csb"
CardResConfig.PuzzleGameMainInofRes = "CardRes/season201904/CashPuzzle/Game_main_info.csb"
CardResConfig.PuzzleGameMainLightRes = "CardRes/season201904/CashPuzzle/Game_main_light.csb"
CardResConfig.PuzzleGameOverRes = "CardRes/season201904/CashPuzzle/Game_over.csb"
CardResConfig.PuzzleGameNumRes = "CardRes/season201904/CashPuzzle/Game_number.csb"
CardResConfig.PuzzleGameCoinsRes = "CardRes/season201904/CashPuzzle/Game_over_Item.csb"
CardResConfig.PuzzleGameGuideRes = "CardRes/season201904/CashPuzzleGuide/GuideBubble.csb"

-- common资源：每个赛季的资源路径除了赛季文件名字不同以外其他路径相同
CardResConfig.commonRes = {
    -- -- wild兑换面板 --
    CardWildExcViewRes = "CardRes/%s/cash_wild_exchange_layer.csb",
    CardWildExcCell201902Res = "CardRes/%s/cash_wild_exchange_cell201902.csb", -- TODO
    CardWildExitRes = "CardRes/%s/cash_wild_exchange_quit.csb",
    CardWildConfirmRes = "CardRes/%s/cash_wild_exchange_confirm.csb",
    -- nado小游戏界面 --
    CardNadoWheelLayerRes = "CardRes/%s/cash_nado_wheel_layer.csb",
    CardNadoWheelLayerPortraitRes = "CardRes/%s/cash_nado_wheel_layer_portrait.csb",
    CardNadoWheelBodyRes = "CardRes/%s/cash_nado_wheel_body.csb",
    CardNadoWheelSpinRes = "CardRes/%s/cash_nado_wheel_spin.csb",
    CardNadoWheelSpinLGRes = "CardRes/%s/cash_nado_wheel_spin_LG.csb",
    CardNadoWheelWheelRes = "CardRes/%s/cash_nado_wheel_chilun.csb",
    CardNadoWheelItemRes = "CardRes/%s/cash_nado_wheel_item.csb",
    CardNadoWheelBubbleRes = "CardRes/%s/cash_nado_wheel_qipao.csb",
    -- CardNadoWheelOverRes = "CardRes/%s/cash_nado_wheel_over.csb",
    CardNadoWheelBigCoinOverRes = "CardRes/%s/cash_nado_wheel_over_EpicPrize.csb",
    CardNadoWheelBigCoinOverIconRes = "CardRes/%s/cash_nado_wheel_Epicdrop.csb",
    CardNadoWheelOverItemRes = "CardRes/%s/cash_nado_wheel_over_item.csb",
    CardNadoWheelOneSpinPopRes = "CardRes/%s/cash_nado_wheel_layer_onespinpop.csb",
    CardNadoWheelSpinHandleRes = "CardRes/%s/cash_nado_wheel_layer_bashou.csb",
    
    -- 回收机界面 --
    CardRecoverViewRes = "CardRes/%s/cash_recover_layer1.csb",
    CardRecoverLockRes = "CardRes/%s/cash_recover_layer1_suo.csb",
    CardRecovertTipRes = "CardRes/%s/cash_recover_layer1_tip.csb",
    CardRecoverWheelRes = "CardRes/%s/cash_recover_layer1_logo.csb",
    CardRecoverLightRes = "CardRes/CardLinkRecover_button.csb", -- TODO
    CardRecoverTip3Res = "CardRes/%s/cash_recover_layer1_qipao.csb",
    CardRecoverRuleRes = "CardRes/%s/cash_recover_rule_New.csb",
    -- 回收机界面 选择卡片 --
    CardRecoverSelViewRes = "CardRes/%s/cash_recover_layer2.csb",
    CardRecoverSelTab1Res = "CardRes/%s/cash_tab_year.csb",
    CardRecoverSelTab2Res = "CardRes/%s/cash_tab_album.csb",
    CardRecoverSelCellRes = "CardRes/%s/cash_recover_layer2_cell.csb",
    CardRecoverMaxTipRes = "CardRes/%s/cash_recover_layer2_tips.csb",
    -- CardRecoverAddLinkRes = "CardRes/%s/CashCardsRecoverCard_link.csb",
    CardRecoverAddLinkRes = "CardsRes201902/CardRes/CashCardsRecoverCard_link.csb",
    CardRecoverSelTabListRes = "CardRes/%s/cash_recover_layer2_list.csb",
    CardRecoverAddGoldRes = "CardRes/%s/cash_recover_layer2_node_jiangli_Extra.csb",
    --乐透
    CardRecoverLettoRes = "CardRes/%s/cash_recover_layer3.csb",
    CardRecoverLettoLogoRes = "CardRes/%s/cash_recover_layer3_logo.csb",
    CardRecoverLettoBottomRes = "CardRes/%s/cash_recover_layer3_bottom.csb",
    CardRecoverLettoBottomBubbleRes = "CardRes/%s/cash_recover_layer3_qipao.csb",
    CardRecoverLettoBottomGuangRes = "CardRes/%s/cash_recover_layer3_bottom_guang.csb",
    CardRecoverLettoJueseRes = "CardRes/%s/cash_recover_layer3_juese.csb",
    CardRecoverLettoLiziRes = "CardRes/%s/cash_recover_layer3_lizi.csb",
    CardRecoverLettoBallRes = "CardRes/%s/cash_recover_layer3_qiu.csb",
    CardRecoverLettoSpinRes = "CardRes/%s/cash_recover_layer3_uiwenzi.csb",
    CardRecoverLettoSpinLightRes = "CardRes/%s/cash_recover_layer3_uiwenziguang.csb",
    CardRecoverLettoSpineBallRes = "CardRes/Other/cash_recover_roll", --spine动画
    CardRecoverLettoItemWildRes = "CardRes/season201903/ui/CardLink202003_Cards_diaoluo_anycard.png", -- base资源
    -- 历史界面 --
    CardHistoryViewRes = "CardRes/%s/cash_history.csb",
    CardHistoryViewCellRes = "CardRes/%s/cash_history_cell.csb",
    -- 集卡完成界面 一个工程中的所有csb列表 --
    -- albumComplete201902 = "CardRes/%s/CardComplete201902_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete201902 = "CardRes/%s/CardComplete201902_zhangjie.csb", -- 打开章节收集成功面板
    linkProgress201902 = "CardRes/%s/CardComplete201902_link.csb", -- link卡收集进度面板
    linkComplete201902 = "CardRes/%s/CardComplete201902_linkover.csb", -- link集齐面板
    CompleteEffectDrop201902 = "CardRes/%s/CardComplete201902_effect_drop.csb", -- 赛季完成/章节完成 界面中两侧的掉落特效
    CompleteEffectCoin201902 = "CardRes/%s/CardComplete201902_effect_coin.csb", -- 赛季完成/章节完成 界面中金币上的特效
    -- 集卡完成界面 一个工程中的所有csb列表 --
    -- albumComplete201903 = "CardRes/%s/CardComplete201903_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete201903 = "CardRes/%s/CardComplete201903_zhangjie.csb", -- 打开章节收集成功面板
    linkProgress201903 = "CardRes/%s/CardComplete201903_challenge_layer.csb", -- link卡收集进度面板
    linkProgressPro201903 = "CardRes/%s/CardComplete201903_challenge_jindu.csb", -- link卡收集进度面板
    linkProgressMark201903 = "CardRes/%s/CardComplete201903_challenge_mark.csb", -- link卡收集进度面板
    linkComplete201903 = "CardRes/%s/CardComplete201903_challenge_reward.csb", -- link集齐面板
    -- 201904集卡完成
    -- albumComplete201904 = "CardRes/%s/CardComplete201904_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete201904 = "CardRes/%s/CardComplete201904_zhangjie.csb", -- 打开章节收集成功面板
    -- 202101集卡完成
    -- albumComplete202101 = "CardRes/%s/CardComplete202101_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202101 = "CardRes/%s/CardComplete202101_zhangjie.csb", -- 打开章节收集成功面板
    -- 202102集卡完成
    -- albumComplete202102 = "CardRes/%s/CardComplete202102_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202102 = "CardRes/%s/CardComplete202102_zhangjie.csb", -- 打开章节收集成功面板
    statueClanComplete202102 = "CardRes/%s/CardComplete202102_zhangjie_statue.csb", -- 打开神像章节收集成功面板
    -- 202104集卡完成
    -- albumComplete202104 = "CardRes/%s/CardComplete202104_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202104 = "CardRes/%s/CardComplete202104_zhangjie.csb", -- 打开章节收集成功面板
    statueClanComplete202104 = "CardRes/%s/CardComplete202104_zhangjie_statue.csb", -- 打开神像章节收集成功面板
    -- 202201集卡完成
    -- albumComplete202201 = "CardRes/%s/CardComplete202201_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202201 = "CardRes/%s/CardComplete202201_zhangjie.csb", -- 打开章节收集成功面板
    statueClanComplete202201 = "CardRes/%s/CardComplete202201_zhangjie_statue.csb", -- 打开神像章节收集成功面板
    -- 202202集卡完成
    -- albumComplete202202 = "CardRes/%s/CardComplete202202_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202202 = "CardRes/%s/CardComplete202202_zhangjie.csb", -- 打开章节收集成功面板
    statueClanComplete202202 = "CardRes/%s/CardComplete202202_zhangjie_statue.csb" -- 打开神像章节收集成功面板
    -- -- 202203集卡完成
    -- albumComplete202203 = "CardRes/%s/CardComplete202203_saiji.csb", -- 打开赛季收集成功面板
    -- clanComplete202203 = "CardRes/%s/CardComplete202203_zhangjie.csb" -- 打开章节收集成功面板
}

-- season资源，每个赛季不一样，所在的路径除了赛季文件名字不同以外其他路径相同
CardResConfig.seasonRes = {
    CardDropView201902Res = "CardsBase201902/CardRes/CardLink_diaoluo.csb",
    -- CardDropLight201902Res = "CardsBase201902/CardRes/CardLink_beijiingguang.csb",
    -- 掉落面板 --
    CardDropView201903Res = "CardRes/%s/cash_drop_layer.csb",
    CardDropLight201903Res = "CardRes/%s/cash_drop_light.csb",
    CardDropPackageTipRes = "CardRes/%s/cash_drop_layer_jiantou.csb",
    CardDropListRes = "CardRes/%s/cash_drop_list.csb",
    CardDropStatueRes = "CardRes/%s/cash201903_drop_statue.csb",
    CardDropWildRes = "CardRes/%s/cash201903_drop_wild.csb",
    CardDropMachineRes = "CardRes/%s/cash_drop_layer_machine.csb",
    CardDropLinkParticleRes = "CardRes/%s/cash_drop_layer_lizi.csb",
    CardBottomNodeRes = "CardRes/%s/cash_season_bottom.csb",
    CardMenuNodeRes = "CardRes/%s/cash_season_menu.csb",
    CardCollectionRes = "CardRes/%s/cash_season_collection.csb",
    CardCollectionCellRes = "CardRes/%s/cash_season_collection_cell.csb",
    CardSeasonLottoRes = "CardRes/%s/cash_season_lotto.csb",
    CardSeasonLottoQipaoRes = "CardRes/%s/cash_season_lotto_qipao.csb",
    CardSeasonNadoWheelRes = "CardRes/%s/cash_season_nadoWheel.csb",
    CardSeasonLuckyWildRes = "CardRes/%s/cash_season_luckyWild.csb",
    --[[-- puzzle小游戏入口 201904加]]
    CardSeasonPuzzleRes = "CardRes/%s/cash_season_cashpuzzle.csb",
    --[[-- 神像入口的UI资源 202102加]]
    CardSeasonStatueRes = "CardRes/%s/cash_season_statue.csb",
    CardSeasonStatueBubbleRes = "CardRes/%s/cash_season_statue_qipao.csb",
    CardSeasonStatueComingRes = "CardRes/%s/cash_season_statue_qipao_coming.csb",
    CardRedPointRes = "CardRes/%s/cash_red_point.csb",
    CardAlbumViewRes = "CardRes/%s/cash_album_layer.csb",
    CardAlbumCellRes = "CardRes/%s/cash_album_cell.csb",
    CardAlbumTitleRes = "CardRes/%s/cash_album_title.csb",
    CardSeasonTimeRes = "CardRes/%s/cash_season_time.csb",
    CardClanViewRes = "CardRes/%s/cash_clan_layer.csb",
    CardClanCellRes = "CardRes/%s/cash_clan_cell.csb",
    CardClanTitleRes = "CardRes/%s/cash_clan_title.csb",
    CardClanTitleLightRes = "CardRes/%s/cash_clan_tltle_light.csb",
    BigCardLayerRes = "CardRes/%s/cash_clan_tanban.csb",
    BigCardTxtRes = "CardRes/%s/cash_clan_tanban_zi.csb",
    CardClanQuestRes = "CardRes/%s/cash_clan_quest.csb",
    CardMiniChipRes = "CardRes/%s/cash_card_chip_new.csb",
    CardMiniTagNewRes = "CardRes/%s/cash_card_tag_new.csb",
    CardMiniTagNumRes = "CardRes/%s/cash_card_tag_num.csb",
    CardMiniTagStarRes = "CardRes/%s/cash_card_star.csb",
    -- 查看普通规则面板 --
    CardRuleRes = "CardRes/%s/cash_menu_rule.csb",
    -- 查看奖励规则面板 --
    CardPrizeRes = "CardRes/%s/cash_menu_prize.csb",
    CardPrizeCellRes = "CardRes/%s/cash_menu_prize_cell.csb",
    CardMiniTagRequestRes = "CardsBase201903/CardRes/%s/cash_card_tag_request.csb",
    CardMiniTagRequestRes_big = "CardsBase201903/CardRes/%s/cash_card_tag_request2.csb",
    -- 普通集卡 开启提示 宣传弹板
    CardOpenNoticeLayerRes = "CardRes/season%s/cash_season_welcome.csb",
    CardOpenNoticeLayerSpinRes = "CardRes/season%s/ui_welcome/spine/CardOpenLayer",
}

CardResConfig.otherRes = {
    CardLettoQiu = "CardRes/Other/qiu", --乐透球
    PrizeSliderBg = "CardRes/Other/Card201903_prize_slider_bg.png",
    PrizeSliderMark = "CardRes/Other/Card201903_prize_slider_marker.png",
    CardCollectionCover = "CardRes/Other/Collection_saishi_icon_%s.png", -- 历史收集赛季封面
    CardCollectionCoverMini = "CardRes/Other/Collection_saishi_mini_%s.png", -- 历史收集赛季封面
    CardMarkRes = "CardRes/Other/CardRecover2_chouma_an%s.png" -- 卡牌的遮罩
}

-- 分赛季的音效
CardResConfig.CARD_SEASON_MUSIC = {
    BackGround = "CardRes/%s/card_bg.mp3"
}

-- 集卡音效
CardResConfig.CARD_MUSIC = {
    DropWow = "CardsBase201902/CardRes/music/card_drop_wow.mp3",
    DropOhYeah = "CardsBase201902/CardRes/music/card_drop_ohyeah.mp3",
    DropSpecial = "CardsBase201902/CardRes/music/card_drop_fly_special_card.mp3",
    DropNormal = "CardsBase201902/CardRes/music/card_drop_fly_normal_card.mp3",
    DropOpenPack = "CardsBase201902/CardRes/music/card_drop_open_pack.mp3",
    FlyCoins = "CardsBase201902/CardRes/music/card_collect_coins.mp3",
    -- BtnClick     = "CardsBase201902/CardRes/music/card_btn_normal.mp3",
    -- BtnBack      = "CardsBase201902/CardRes/music/card_btn_back_x.mp3",
    -- BtnOpenView     = "Sounds/soundOpenView.mp3",
    -- BtnHideView     = "Sounds/soundHideView.mp3",
    BtnClick = "Sounds/soundOpenView.mp3", -- SOUND_ENUM.MUSIC_BTN_CLICK,
    BtnBack = "Sounds/soundHideView.mp3", -- SOUND_ENUM.MUSIC_BTN_CLICK,
    RecoverScroll = "CardRes/music/card_recover_wheel_single_scroll.mp3",
    RecoverRewardShow = "CardRes/music/card_recover_reward_show.mp3",
    RecoverRewardStart = "CardRes/music/card_recover_reward_start.mp3",
    RecoverRewardCoin = "CardRes/music/card_recover_reward_coin.mp3",
    RecoverWheelAward = "CardRes/music/card_recover_wheel_award.mp3",
    RecoverWheelCoinRaise = "CardRes/music/card_recover_wheel_coinraise.mp3",
    RecoverWheelCoinRaise2 = "CardRes/music/card_recover_wheel_coinraise2.mp3",
    --letto
    CardLettoBall = "CardRes/music/CardLettoBall.mp3", --球进入管道
    CardLettoBg = "CardRes/music/CardLettoBg.mp3", --背景
    CardLettoEnter = "CardRes/music/CardLettoEnter.mp3", --进入
    CardLettoReward = "CardRes/music/CardLettoReward.mp3", --奖励
    -- 201903掉落
    CardDropBoxOpen = "CardRes/music/card_drop_box_open.mp3",
    CardDropChipAppear = "CardRes/music/card_drop_chip_appear.mp3",
    CardDropFlyLizi = "CardRes/music/card_drop_flylizi.mp3",
    CardDropNadoWheelAppear = "CardRes/music/card_nadowheel_appear.mp3",
    CardDropNadoWheelShake = "CardRes/music/card_nadowheel_shake.mp3",
    CardDropNadoWheelMoveLeft = "CardRes/music/card_nadowheel_moveleft.mp3",
    -- 201903nado机
    CardNadoMachineWinPrize = "CardRes/music/card_nadomachine_winprize.mp3",
    CardNadoMachineRoll = "CardRes/music/card_nadomachine_roll.mp3",
    RecoverAddCards = {
        "CardRes/music/card_recover_exchange_addcard1.mp3",
        "CardRes/music/card_recover_exchange_addcard2.mp3",
        "CardRes/music/card_recover_exchange_addcard3.mp3",
        "CardRes/music/card_recover_exchange_addcard4.mp3",
        "CardRes/music/card_recover_exchange_addcard5.mp3",
        "CardRes/music/card_recover_exchange_addcard6.mp3",
        "CardRes/music/card_recover_exchange_addcard7.mp3",
        "CardRes/music/card_recover_exchange_addcard8.mp3"
    },
    AlbumSwitchPage = "CardRes/music/card_album_switch_page.mp3",
    AlbumOpenBook = "CardRes/music/card_album_openbook.mp3",
    --link小游戏
    LinkItemSpin = "CardRes/music/card_link_item_spin.mp3", --道具旋转
    LinkRewardShow = "CardRes/music/card_link_reward_show.mp3", --展示奖励
    LinkRootSpin = "CardRes/music/card_link_root_spin.mp3", --机器旋转
    LinkLayerBig = "CardRes/music/card_link_layer_click2big.mp3",
    LinkBubble = "CardRes/music/card_link_qipao.mp3",
    LinkRootLightning = "CardRes/music/card_link_root_enter_shandian.mp3",
    --卡册完成音效
    CompleteBg = "CardRes/music/card_complete_bg.mp3", --背景音乐
    CompleteChinafortune = "CardRes/music/card_complete_chinafortune.mp3", --chinafortune
    CompleteDone = "CardRes/music/card_complete_done.mp3", --completed
    CompleteGoodjob = "CardRes/music/card_complete_goodjob.mp3", --goodjob
    CompleteLvpiaodai = "CardRes/music/card_complete_lvpiaodai.mp3", --绿丝带
    CompleteYanhua = "CardRes/music/card_complete_yanhua.mp3", --烟花
    CompletelinkAllDone = "CardRes/music/card_complete_linkAllDone.mp3", --所有link收集完成
    -- wildcard
    DropClickWild = "CardsBase201902/CardRes/music/card_drop_click_wild.mp3", -- Cash Link项目-集卡活动-Wild Card点击
    -- small game
    CardSmallGameBg = "CardRes/music/card_small_game_bg.mp3", --小游戏背景音乐
    CardSmallGameDialog = "CardRes/music/card_small_game_dialog.mp3", --结算弹板弹出时的音效
    CardSmallGameDissolve = "CardRes/music/card_small_game_dissolve.mp3", --格子溶解时效果的音效
    CardSmallGameItem = "CardRes/music/card_small_game_item.mp3", --在结算弹板中，获得道具时的音效
    CardSmallGameMove = "CardRes/music/card_small_game_move.mp3", --光标移动音效
    CardSmallGameSelectDADA = "CardRes/music/card_small_game_select_dadada.mp3", --选中闪动之后的音效
    -- 201904赛季集卡小游戏音效
    CardPuzzleGameOpenBox = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_openBox.mp3",
    CardPuzzleGameGolden = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_golden.mp3",
    CardPuzzleGameBig1 = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_changeBig1.mp3",
    CardPuzzleGameBig2 = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_changeBig2.mp3",
    CardPuzzleGameAddPick = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_addPick.mp3",
    CardPuzzleGameChipEnd = "CardRes/season201904/CashPuzzle/music/music_card_puzzle_game_chipEnd.mp3",
    -- 神像小游戏的背景音乐
    StatueBackGround = "CardRes/season202102/Statue/music/statuePickBg.mp3",
    -- 神像小游戏音效
    StatuePickBigBoxAppear = "CardRes/season202102/Statue/music/statuePick_bigBoxAppear.mp3",
    StatuePickBigBoxDispersed = "CardRes/season202102/Statue/music/statuePick_bigBoxDispersed.mp3",
    StatuePickBoxGrey = "CardRes/season202102/Statue/music/statuePick_boxGrey.mp3",
    StatuePickBoxLvUp = "CardRes/season202102/Statue/music/statuePick_boxLvUp.mp3",
    StatuePickBoxOpen = "CardRes/season202102/Statue/music/statuePick_boxOpen.mp3",
    StatuePickBoxClick = "CardRes/season202102/Statue/music/statuePick_boxClick.mp3",
    -- 神像界面音效
    StatueFog = "CardRes/season202102/Statue/music/statue_fog.mp3",
    StatuePeopleLight = "CardRes/season202102/Statue/music/statue_peopleLight.mp3",
    StatueBuffLight = "CardRes/season202102/Statue/music/statue_buffLight.mp3",
    StatueBuffUnlock = "CardRes/season202102/Statue/music/statue_buffUnlock.mp3",
    StatueBoxPlayClick = "CardRes/season202102/Statue/music/statue_boxPlayClick.mp3",
    StatueFly2People = "CardRes/season202102/Statue/music/statue_fly2People.mp3",
    StatueFly2Lock = "CardRes/season202102/Statue/music/statue_fly2Lock.mp3",
    StatueNewCard = "CardRes/season202102/Statue/music/statue_newCard.mp3"
}
