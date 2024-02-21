--[[
    集卡系统通用结构配置
    注：数据结构 !临时粘贴自服务器proto!
       字段和具体数据 ！需要确认和修改！
--]]
GD.CardSysConfigs = {}

CardSysConfigs.PuzzleGameGuide = true

--卡片配置
CardSysConfigs.CardInfoConfig = {
    cardId = 1, --卡id
    number = 2, --编号
    year = 3, --年份
    season = 4, --赛季
    clanId = 5, --所属卡组id
    albumId = 6, --所属卡册id
    type = 7, --类型
    star = 8, --星级
    name = 9, --名字
    icon = 10, --icon
    count = 11, --卡的数量
    linkCount = 12, --如果是link卡，link剩余次数
    newCard = 13, --是否是新卡标志
    description = 14, --卡片描述
    source = 15, --卡片来源
    firstDrop = 16, --首次掉落
    nadoCount = 17, --如果是nado卡，对应的送nado游戏的次数
    gift = 18, --是否可以赠送
    greenPoint = 19, -- 多余的卡转化成商城积分
    goldPoint = 20, -- 多余的卡转化成商城积分
    exchangeCoins = 21, -- 新手期多余的卡兑换的金币，只有掉落的时候才会赋值
    round = 22 --当前卡所属的轮次，掉落中使用的
}
CardSysConfigs.CardClone = function(tInfo)
    local card = {}
    card.cardId = tInfo.cardId
    card.number = tInfo.number
    card.year = tInfo.year
    card.season = tInfo.season
    card.clanId = tInfo.clanId
    card.albumId = tInfo.albumId
    card.type = tInfo.type
    card.star = tInfo.star
    card.name = tInfo.name
    card.icon = tInfo.icon
    card.count = tInfo.count
    card.linkCount = tInfo.linkCount
    card.newCard = tInfo.newCard
    card.description = tInfo.description
    card.source = tInfo.source
    card.firstDrop = tInfo.firstDrop
    card.nadoCount = tInfo.nadoCount
    card.gift = tInfo.gift
    card.greenPoint = tInfo.greenPoint
    card.goldPoint = tInfo.goldPoint
    card.exchangeCoins = tonumber(tInfo.exchangeCoins or 0)
    card.round = tInfo.round
    return card
end

-- 网络访问地址配置  字段目前与CardProto_pb中协议结构同名 --
-- TEST URL 192.168.2.35:9001
CardSysConfigs.Url = {
    CardsInfoRequest = "/v1/card/info", --   ▪  登陆游戏，客户端请求集卡基础信息接口，服务器返回以年度为单位的卡册基础数据
    CardAlbumRequest = "/v1/card/album", --   ▪  查询某一个赛季卡册所有数据接口
    CardDropHistoryRequest = "/v1/card/history", --   ▪  查询历史掉落数据接口
    CardWheelAllCardsRequest = "/v1/card/wheel/allcards", --   ▪  回收机可回收年度的所有卡片数据接口
    CardWheelRequest = "/v1/card/wheel/cards", --   ▪  回收机回收卡片spin请求接口
    CardLettoRequest = "/v1/card/wheel/letto", --   ▪  回收机回收乐透请求接口
    CardLinkPlayRequest = "/v1/card/link/play", --   ▪  Link卡请求link游戏接口
    CardNadoPlayRequest = "/v1/card/nado/play", --   ▪  Link卡请求link游戏接口
    CardExchangeYearCardsRequest = "/v1/card/exchange/allcards", --   ▪  wild卡可兑换的年度所有卡片数据接口
    CardExchangeRequest = "/v1/card/exchange/card", --   ▪  wild卡请求兑换接口
    CardViewRequest = "/v1/card/view/cards", --   ▪  浏览卡片请求接口，重置卡片new状态
    CardSpecialGameRequest = "/v1/card/special/play", --   ▪  小游戏
    CardVegasTornadoPlayRequest = "/v1/card/vegasTornado/play", -- 第三赛季小游戏请求接口
    CardRankRequest = "/v1/card/rank", -- 集卡排行榜
    ShortCardAlbumResult = "/v1/card/shortalbum", --黑曜卡特殊卡册 查询某一个赛季卡册所有数据接口
    -- CardNoviceAlbumRequest = "/v1/card/newuseralbum" --新手期卡册 查询某一个赛季卡册所有数据接口
}

-- 卡片掉落来源说明配置 --
CardSysConfigs.DropFromDes201902 = {
    [101] = "Level Up",
    [102] = "Make any purchase",
    [103] = "Friend's Gifts",
    [104] = "Spin in any slot",
    [105] = "Play any challenging experience",
    [201] = "Collect Cash Money Bonus",
    [202] = 'Spin on slots with "Nado" feature',
    [203] = 'Reach levels ending with "00" or "50"',
    [204] = "Getting a Club Pass or Completing a Quest in Medium difficulty",
    [205] = "Fill the Bar in Pass or Completing a Quest in Hard difficulty"
}

CardSysConfigs.DropFromDes201903 = {
    [102] = "Chance to win with purchase",
    [103] = "As gifts from friends",
    [104] = "Chance to win with every spin",
    [105] = "Playing any feature games",
    [201] = "Collecting the Cash Money bonus",
    [202] = 'Playing "NADO" featured games',
    [203] = "Every 50 levels",
    [204] = "Medium Difficulty Mode In Quest",
    [205] = "Completing the Season Ticket",
    [206] = "Hard Difficulty Mode In Quest",
    [207] = "Any Difficulty Mode In Quest",
    [208] = "Completing Lucky Bonus in God Statue",
    [301] = "Play Mythic Game",
    [302] = "Play Quest Wheel",
    [401] = "RANDOMLY HITS IN",
    [402] = "QUEST, EVENTS, DAILY MISSION,",
    [403] = "BALLOON RUSH, SPECIAL OFFERS.",
    [491] = "EVENT ENDED",
    [501] = "Daily Bonus",
    [502] = "Blast Game",
    [503] = "Quest Game",
    [504] = "Vegas Season",
    [510] = "Blast Level 1",
    [511] = "Blast Level 3",
    [512] = "Blast Level 4",
    [513] = "Blast Level 5",
    [514] = "Blast Level 6",
    [515] = "Blast Level 7",
    [516] = "Blast Level 8",
    [517] = "Blast Level 9",
    [518] = "Blast Level 10",
    [520] = "Quest Phase 1",
    [521] = "Quest Phase 2",
    [522] = "Quest Phase 3",
    [601] = "Randomly hits in Mythic Game and Quest",
}

-- 卡片掉落来源图片配置 --
CardSysConfigs.DropFromIconDes = {
    [101] = "CashCards_tu_jiantou.png",
    [102] = "CashCards_tu_jinbi.png",
    [103] = "CashCards_tu_liwu.png",
    [104] = "CashCards_tu_spin.png"
}

-- 卡牌类型
CardSysConfigs.CardType = {
    normal = "NORMAL",
    golden = "GOLDEN",
    link = "LINK",
    wild = "WILD",
    wild_normal = "WILD_NORMAL",
    wild_link = "WILD_LINK",
    wild_golden = "WILD_GOLDEN",
    wild_obsidian = "BLACK_WILD",
    wild_magic = "QUEST_WILD",
    wild_magic_red = "QUEST_WILD_RED",
    wild_magic_purple = "QUEST_WILD_PURPLE",
    puzzle = "PUZZLE",
    statue_green = "STATUE_GREEN",
    statue_blue = "STATUE_BLUE",
    statue_red = "STATUE_RED",
    quest_new = "QUEST",
    quest_magic_red = "QUEST_RED",
    quest_magic_purple = "QUEST_PURPLE",
    obsidian = "BLACK_GOLDEN"
}

-- 掉落界面卡牌排序优先级
CardSysConfigs.DropCardPriority = {
    [CardSysConfigs.CardType.normal] = 1,
    [CardSysConfigs.CardType.golden] = 2,
    [CardSysConfigs.CardType.link] = 3,
    [CardSysConfigs.CardType.wild] = 4,
    [CardSysConfigs.CardType.wild_normal] = 4,
    [CardSysConfigs.CardType.wild_link] = 4,
    [CardSysConfigs.CardType.wild_golden] = 4,
    [CardSysConfigs.CardType.puzzle] = 5,
    [CardSysConfigs.CardType.statue_green] = 6,
    [CardSysConfigs.CardType.statue_blue] = 6,
    [CardSysConfigs.CardType.statue_red] = 6,
    [CardSysConfigs.CardType.quest_new] = 7,
    [CardSysConfigs.CardType.obsidian] = 8,
    [CardSysConfigs.CardType.wild_obsidian] = 9,
    [CardSysConfigs.CardType.wild_magic] = 10,
    [CardSysConfigs.CardType.wild_magic_red] = 10,
    [CardSysConfigs.CardType.wild_magic_purple] = 10,
    [CardSysConfigs.CardType.quest_magic_red] = 11,
    [CardSysConfigs.CardType.quest_magic_purple] = 11,
}

-- 卡牌赛季类型
CardSysConfigs.CardSeasonStatus = {
    offline = "OFF_LINE",
    online = "ON_LINE",
    coming = "COMING_SOON"
}

-- 卡牌章节类型
CardSysConfigs.CardClanType = {
    normal = "NORMAL",
    special = "SPECIAL",
    puzzle_normal = "PUZZLE_NORMAL",
    puzzle_golden = "PUZZLE_GOLDEN",
    puzzle_link = "PUZZLE_LINK",
    quest = "QUEST",
    statue_left = "SPECIAL_LEFT",
    statue_right = "SPECIAL_RIGHT",
    quest_new = "QUEST_NEW",
    quest_magic = "QUEST_MAGIC",
    obsidian = "BLACK_GOLDEN"
}

-- 卡牌掉落
CardSysConfigs.CardDropType = {
    normal = "NORMAL", -- 普通卡包
    link = "LINK", -- link卡包
    golden = "GOLDEN", -- 金卡包
    single = "SINGLE", -- 单卡
    wild = "WILD", -- wild卡
    wild_normal = "WILD_NORMAL", -- wild卡
    wild_link = "WILD_LINK", -- wild卡
    wild_golden = "WILD_GOLDEN", -- wild卡
    wild_obsidian = "BLACK_WILD", -- wild卡
    puzzle = "PUZZLE", -- 单独掉落拼图卡
    statue_green = "STATUE_GREEN", -- 神像卡
    statue_blue = "STATUE_BLUE", -- 神像卡
    statue_red = "STATUE_RED", -- 神像卡
    merge = "merge", -- 客户端合并的卡包
    obsidian_gold = "BLACK_GOLDEN3", --黑曜卡 金
    obsidian_copper = "BLACK_GOLDEN1", --黑曜卡 铜
    obsidian_purple = "BLACK_GOLDEN2", --黑曜卡 紫
    quest_wild_red = "QUEST_WILD_RED", -- 特殊卡册wild卡 红
    quest_wild_purple = "QUEST_WILD_PURPLE", -- 特殊卡册wild卡 红
    mergeObsidian = "mergeObsidian" -- 客户端合并的黑曜卡包
}

-- link卡游戏spin返回结果类型
CardSysConfigs.CardLinkPlayRewardType = {
    coins = "COINS",
    package = "PACKAGE",
    vipPoints = "VIP_POINTS",
    coinsRespin = "COINS_RESPIN"
}

-- 卡册界面中，每个赛季的卡册都不尽相同，这里配置一下 wild章节行数列数
CardSysConfigs.CardAlbumCellResType = {
    ["201901"] = 1,
    ["201902"] = 2
}

-- 进入集卡系统的方式
CardSysConfigs.CardSysEnterType = {
    Lobby = 1, -- 点击大厅按钮进入卡册章节
    Link = 2 -- link自动跳转到卡册章节
}

-- TEST NOTIFY
CardSysConfigs.NOTIFY_SET_STRING = "NOTIFY_SET_STRING"

CardSysConfigs.DropViewTitle = {
    ["CONGRATS!"] = "title_congrats",
    ["AWESOME!"] = "title_awesome",
    ["WOW!"] = "title_wow",
    ["OH YEAH!"] = "title_ohyeah"
}
-- 需要同步掉落类型配置
CardSysConfigs.DropViewType = {
    ["NORMAL"] = {sourceKey = "normalPackage", bgLight = true, packageType = 1, isTap = true, showClose = true},
    ["LINK"] = {sourceKey = "linkPackage", bgLight = true, packageType = 2, isTap = true, showClose = true},
    ["GOLDEN"] = {sourceKey = "goldenPackage", bgLight = true, packageType = 6, isTap = true, showClose = false},
    ["SINGLE"] = {sourceKey = "single", showClose = true},
    ["WILD"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["WILD_NORMAL"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["WILD_LINK"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["WILD_GOLDEN"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["BLACK_WILD"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["QUEST_WILD"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["QUEST_WILD_RED"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["QUEST_WILD_PURPLE"] = {sourceKey = "wildCard", isWild = true, bgLight = true, packageType = 3, isTap = true, showClose = false},
    ["PUZZLE"] = {sourceKey = "statuePackage", bgLight = true, packageType = 4, isTap = true, showClose = false},
    ["STATUE_GREEN"] = {sourceKey = "statuePackage", bgLight = true, packageType = 4, isTap = true, showClose = false},
    ["STATUE_BLUE"] = {sourceKey = "statuePackage", bgLight = true, packageType = 4, isTap = true, showClose = false},
    ["STATUE_RED"] = {sourceKey = "statuePackage", bgLight = true, packageType = 4, isTap = true, showClose = false},
    ["BLACK_GOLDEN1"] = {sourceKey = "obsidianPackage", bgLight = true, packageType = 1, isTap = true, showClose = true},
    ["BLACK_GOLDEN2"] = {sourceKey = "obsidianPackage", bgLight = true, packageType = 1, isTap = true, showClose = true},
    ["BLACK_GOLDEN3"] = {sourceKey = "obsidianPackage", bgLight = true, packageType = 1, isTap = true, showClose = true},
    ["merge"] = {sourceKey = "mergePackage", packageType = 5, showClose = false},
    ["mergeObsidian"] = {sourceKey = "mergePackage", packageType = 5, showClose = false}
}

-- 集卡掉落来源
CardSysConfigs.CARD_DROP_SOURCE = {
    ["Card Gifts"] = {
        -- 卡册集满赠送wild卡
        wildCard = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A WILD CHIP!"
        },
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A CHIP CASE!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE!"
        }
    },
    ["Link Featured Game"] = {
        source = "Link Featured Game", -- Link关卡
        linkPackage = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE"
        },
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }
    },
    ["Tornado Featured Game"] = {
        source = "Tornado Featured Game", -- Tornado关卡
        linkPackage = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE"
        },
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }
    },
    ["Random Spin"] = {
        source = "Random Spin", -- 关卡Spin
        autoCloseDropUI = true,
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP!"
        },
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }
    },
    ["Link Machine"] = {
        source = "Link Machine", -- Link小游戏
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A CHIP CASE FROM TORNADO MACHINE!"
        },
        goldenPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A GOLD CHIP FROM TORNADO MACHINE!"
        }
    },
    ["Lucky Lotto"] = {
        source = "Lucky Lotto", -- 回收机
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A CHIP CASE FROM LUCKY LOTTO!"
        },
        wildCard = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A WILD CHIP FROM LUCKY LOTTO!"
        }
    },
    ["Purchase"] = {
        source = "Purchase", -- 购买获得
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A CHIP CASE FOR YOUR PURCHASE!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE FOR YOUR PURCHASE!"
        },
        wildCard = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A WILD CHIP FOR YOUR PURCHASE!"
        },
        goldenPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A GOLD CHIP FROM PURCHASE!"
        }
    },
    ["Cash Money"] = {
        source = "Cash Money", -- 金库领取
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A TORNADO CHIP CASE FROM CASH MONEY BONUS!"
        }
    },
    ["Wild Exchange"] = {
        source = "Wild Exchange", -- wild兑换
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "A CHOSEN CHIP FROM WILD CHIP!"
        }
    },
    ["Level Up"] = {
        source = "Level Up", -- 升级
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A CHIP CASE ON SPECIAL LEVEL!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE ON SPECIAL LEVEL!"
        },
        single = {
            -- 升级没说给散卡
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE ON SPECIAL LEVEL!"
        }
    },
    ["New Player"] = {
        source = "New Player", -- 新赛季引导针对新用户
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!"
        },
        single = {
            -- 升级没说给散卡
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!!"
        }
    },
    ["New Season"] = {
        source = "New Season", -- 新赛季引导
        normalPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!"
        },
        single = {
            -- 升级没说给散卡
            title = "WOW!",
            music = "DropWow",
            des = "A CHIP CASE FROM CASH TORNADO!!"
        }
    },
    -- ["Mission"] = {
    --     source = "Mission",                        -- 任务进度奖励
    --     linkPackage = {
    --         title = "WOW!",
    --         music = "DropWow",
    --         des = "A TORNADO CHIP CASE FROM MISSION REWARD!",
    --     },
    -- },
    ["Quest Rewards"] = {
        source = "Quest Rewards", -- Quest奖励
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM QUEST REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM QUEST REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM QUEST REWARD!"
        }
    },
    ["FindRewards"] = {
        source = "Find Rewards", -- Find奖励
        normalPackage = {
            title = "CONGRATS!",
            des = "A CARD PACK FROM FIND REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM FIND REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM FIND REWARD!"
        }
    },
    ["Bingo Rewards"] = {
        source = "Bingo Rewards", -- Bingo奖励
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM BINGO REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM BINGO REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM BINGO REWARD!"
        }
    },
    ["Bingo Play"] = {
        source = "Bingo Play", -- Bingo玩家奖励
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM BINGO REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM BINGO REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM BINGO REWARD!"
        }
    },
    ["Quest Wheel Play"] = {
        source = "Quest Wheel Play", -- Bingo奖励
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM QUEST WHEEL REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM QUEST WHEEL REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM QUEST WHEEL REWARD!"
        }
    },
    ["FriendGifts"] = {
        source = "Friend's Gifts" -- 赠送
    },
    ["InboxGifts"] = {
        source = "Inbox Gifts" -- 邮件奖励
    },
    ["Find Play"] = {
        source = "Find Rewards", -- Find奖励
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }, -- 卡册集满赠送wild卡
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM FIND REWARD!"
        },
        wildCard = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A WILD CHIP!"
        },
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE!"
        }
    },
    ["Cash Club Benefit"] = {
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A TORNADO CHIP CASE!"
        }
    },
    ["Card Mission"] = {
        source = "Card Mission", -- 任务活动单个任务也会获得卡牌
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A TORNADO CHIP PACK FROM CHIP MISSION REWARD!"
        },
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }, -- 卡册集满赠送wild卡
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM CHIP MISSION REWARD!"
        }
    },
    ["Super Spin Card"] = {
        source = "Super Spin Card", -- 任务活动单个任务也会获得卡牌
        linkPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "A TORNADO CHIP CASE FROM SUPER SPIN REWARD!"
        },
        single = {
            title = "OH YEAH!",
            music = "DropOhYeah",
            des = "YOU'VE RECEIVED %s !"
        }, -- 卡册集满赠送wild卡
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM SUPER SPIN REWARD!"
        },
        wildCard = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A WILD CHIP!"
        }
    },
    ["Defender Box"] = {
        source = "Defender Box", -- defender 宝箱奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM DEFENDER BOX REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM DEFENDER BOX REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM DEFENDER BOX REWARD!"
        }
    },
    ["Defender BOSS"] = {
        source = "Defender BOSS", -- defender 宝箱奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM DEFENDER BOSS REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM DEFENDER BOSS REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM DEFENDER BOSS REWARD!"
        }
    },
    ["Defender Special"] = {
        source = "Defender Special", -- defender 阶段奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM DEFENDER SPECIAL REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM DEFENDER SPECIAL REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM DEFENDER SPECIAL REWARD!"
        }
    },
    ["Defender Rewards"] = {
        source = "Defender Rewards", -- defender 阶段奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM DEFENDER STAGE REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM DEFENDER STAGE REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM DEFENDER STAGE REWARD!"
        }
    },
    ["Card Picks"] = {
        source = "Card Picks",
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !!"
        },
        statuePackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM LUCKY BONUS!"
        }
    },
    ["Bonus hunt"] = {
        source = "Bonus hunt", -- defender 阶段奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM BONUS HUNT REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A TORNADO CHIP CASE FROM BONUS HUNT REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CHIP FROM BONUS HUNT REWARD!"
        },
        goldenPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A GOLD CHIP FROM BONUS HUNT!"
        }
    },
    ["Challenge Rewards"] = {
        source = "Challenge Rewards", -- defender 阶段奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CARD PACK FROM CHALLENGE REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A LINK CARD PACK FROM CHALLENGE REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CARD FROM CHALLENGE REWARD!"
        }
    },
    ["Challenge Rank Rewards"] = {
        source = "Challenge Rank Rewards", -- defender 阶段奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CARD PACK FROM CHALLENGE RANK REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A LINK CARD PACK FROM CHALLENGE RANK REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CARD FROM CHALLENGE RANK REWARD!"
        }
    },
    ["Level Rush"] = {
        source = "Level Rush", -- level rush奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CARD PACK FROM LEVEL RUSH REWARD!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A LINK CARD PACK FROM LEVEL RUSH REWARD!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CARD FROM LEVEL RUSH REWARD!"
        }
    },
    ["Mythic Chip Game"] = {
        source = "Mythic Chip Game", -- level rush奖励
        single = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED %s !"
        },
        normalPackage = {
            title = "CONGRATS!",
            des = "A CHIP CASE FROM MYTHIC CHIP GAME!"
        },
        linkPackage = {
            title = "CONGRATS!",
            des = "A LINK CARD PACK FROM MYTHIC CHIP GAME!"
        },
        wildCard = {
            title = "CONGRATS!",
            des = "A WILD CARD FROM MYTHIC CHIP GAME!"
        },
        goldenPackage = {
            title = "WOW!",
            music = "DropWow",
            des = "YOU'VE RECEIVED A GOLD CHIP FROM MYTHIC CHIP GAME!"
        }           
    }     
}

-- 集卡事件
CardSysConfigs.ViewEventType = {
    CARD_MENU_CLOSE = "CARD_MENU_CLOSE",
    CARD_LETTO_COLLECT = "CARD_LETTO_COLLECT", -- 乐透领取奖励后要刷新其他界面
    NOTIFY_CHECK_CLAN_NEW = "NOTIFY_CHECK_CLAN_NEW", -- 卡组界面刷新newtag标记
    CARD_NADO_WHEEL_ROLL_OVER = "CARD_NADO_WHEEL_ROLL_OVER", -- nado轮盘结束后要刷新章节选择界面的小红点
    CARD_NADO_WHEEL_CLOSE = "CARD_NADO_WHEEL_CLOSE", -- nado轮盘主界面关闭
    CARD_NADO_WHEEL_REWARD_CLOSE = "CARD_NADO_WHEEL_REWARD_CLOSE", -- nado轮盘结算界面关闭
    CARD_ALBUM_LIST_UPDATE = "CARD_ALBUM_LIST_UPDATE", -- 掉落卡牌后要刷新一下卡牌选择界面
    CARD_COLLECTION_ENTER_ALBUM = "CARD_COLLECTION_ENTER_ALBUM",
    CARD_COLLECTION_CLICK_SYNC = "CARD_COLLECTION_CLICK_SYNC", -- 点击下载一个赛季，同步其他赛季使用同一个下载路径的
    CARD_PUZZLE_GAME_CHECK_CHANGE_BOX = "CARD_PUZZLE_GAME_CHECK_CHANGE_BOX", -- 检测变箱子
    CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START = "CARD_PUZZLE_GAME_CHANGE_GOLDENBOX_START", -- 银宝箱变成金宝箱
    CARD_PUZZLE_GAME_UPDATE_ITEMS = "CARD_PUZZLE_GAME_UPDATE_ITEMS", -- 刷新小游戏界面的碎片
    CARD_PUZZLE_GAME_UPDATE_PURCHASE = "CARD_PUZZLE_GAME_UPDATE_PURCHASE", -- 刷新小游戏界面的付费相关界面
    CARD_PUZZLE_GAME_UPDATE_PICK = "CARD_PUZZLE_GAME_UPDATE_PICK", -- 刷新小游戏界面消耗次数后相关界面
    CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_START = "CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_START", -- 小游戏界面开始飞碎片逻辑
    CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_OVER = "CARD_PUZZLE_GAME_OPENBOX_FLY_PUZZLE_OVER", -- 小游戏界面飞碎片结束
    CARD_PUZZLE_GAME_UPDATE_BOX = "CARD_PUZZLE_GAME_UPDATE_BOX", -- 刷新小游戏界面的宝箱状态
    CARD_PUZZLE_GAME_COLLECT_REWARD = "CARD_PUZZLE_GAME_COLLECT_REWARD", -- 收取小游戏奖励
    CARD_PUZZLE_GAME_JUMP_TO_SHOP = "CARD_PUZZLE_GAME_JUMP_TO_SHOP", -- 小游戏进入商店
    CARD_PUZZLE_GAME_CHECK_OVER = "CARD_PUZZLE_GAME_CHECK_OVER", -- 一次打开宝箱后续的弹框都结束
    CARD_PUZZLE_GAME_BUY_MORE_UPDATE = "CARD_PUZZLE_GAME_BUY_MORE_UPDATE", -- BUYMORE界面刷新
    CARD_NEW_SEASON_OPEN = "CARD_NEW_SEASON_OPEN", -- 集卡新赛季开启
    CARD_YEAR_TAB_UPDATE = "CARD_YEAR_TAB_UPDATE",
    CARD_ALBUM_TAB_UPDATE = "CARD_ALBUM_TAB_UPDATE",
    CARD_RECOVER_EXCHANGE_CLICK_CELL = "CARD_RECOVER_EXCHANGE_CLICK_CELL",
    CARD_WILD_EXCHANGE_CLICK_CELL = "CARD_WILD_EXCHANGE_CLICK_CELL",
    CARD_WILD_EXCHANGE_UPDATE_BTN_GO = "CARD_WILD_EXCHANGE_UPDATE_BTN_GO",
    CARD_WILD_EXCHANGE_FRAMELOAD_START = "CARD_WILD_EXCHANGE_FRAMELOAD_START",
    CARD_WILD_EXCHANGE_FRAMELOAD_CLEARUP = "CARD_WILD_EXCHANGE_FRAMELOAD_CLEARUP",
    CARD_COUNTDOWN_UPDATE = "CARD_COUNTDOWN_UPDATE", -- 计时器
    CARD_STATUE_OPEN = "CARD_STATUE_OPEN",
    CARD_STATUE_UPDATE_TIME = "CARD_STATUE_UPDATE_TIME",
    CARD_STATUE_UPDATE_CHIP = "CARD_STATUE_UPDATE_CHIP",
    CARD_STATUE_LEVELUP = "CARD_STATUE_LEVELUP", -- 神像升级事件
    CARD_STATUE_DROP_CARD = "CARD_STATUE_DROP_CARD", -- 掉落神像卡
    CARD_STATUE_LEVELUP_ANIMA_CARD = "CARD_STATUE_LEVELUP_ANIMA_CARD", -- 神像升级开始:筹码动效
    CARD_STATUE_LEVELUP_ANIMA_PEOPLE = "CARD_STATUE_LEVELUP_ANIMA_PEOPLE", -- 神像升级:雕像动效
    CARD_STATUE_LEVELUP_ANIMA_OVER = "CARD_STATUE_LEVELUP_ANIMA_OVER", -- 神像升级结束
    CARD_STATUE_LEVELUP_LIZI_FLY2PEOPLE = "CARD_STATUE_LEVELUP_LIZI_FLY2PEOPLE", -- 神像升级粒子飞到雕像位置
    CARD_STATUE_LEVELUP_LIZI_FLY2LOCK = "CARD_STATUE_LEVELUP_LIZI_FLY2LOCK", -- 神像升级粒子飞到解锁位置
    CARD_EXCHANGE_TAB_UPDATE = "CARD_EXCHANGE_TAB_UPDATE", --卡牌兑换界面 切换页签
    CARD_RECOVER_COUNTDOWN_CHANGE = "CARD_RECOVER_COUNTDOWN_CHANGE", -- 回收机倒计时状态变动
    CARD_ALBUM_ROUND_CHANGE = "CARD_ALBUM_ROUND_CHANGE" -- 轮次更改
}

ViewEventType.CARD_ONLINE_ALBUM_OVER = "CARD_ONLINE_ALBUM_OVER" -- 在线赛季结束
ViewEventType.ONRECIEVE_CARDS_ALBUM_REQ_SUCCESS = "ONRECIEVE_CARDS_ALBUM_REQ_SUCCESS" -- 查询某一个赛季卡册所有数据接口 成功
ViewEventType.NOTIFY_UPDATE_CARD_OPEN_SHOW_DATA = "NOTIFY_UPDATE_CARD_OPEN_SHOW_DATA" -- 刷新 新手期集卡开启活动 轮播展示信息
ViewEventType.CLOSE_REMOVE_NEW_USER_CARD_OPEN_HALL_SLIDE = "CLOSE_REMOVE_NEW_USER_CARD_OPEN_HALL_SLIDE" -- 新手期集卡开启活动 到期移除轮播展示

-- TODO:新赛季时必加表
CardSysConfigs.SEASON_LIST = {
    ["302301"] = {
        id = 302301,
        albumPath = "GameModule.Card.season302301.CardAlbumView",
        seasonPath = "GameModule.Card.season302301.CardSeason"
    },
    ["201901"] = {
        id = 201901,
        albumPath = "GameModule.Card.season201901.CardAlbumView",
        seasonPath = "GameModule.Card.season201901.CardSeason"
    },
    ["201902"] = {
        id = 201902,
        albumPath = "GameModule.Card.season201902.CardAlbumView",
        seasonPath = "GameModule.Card.season201902.CardSeason"
    },
    ["201903"] = {
        id = 201903,
        albumPath = "GameModule.Card.season201903.CardAlbumView",
        seasonPath = "GameModule.Card.season201903.CardSeason"
    },
    ["201904"] = {
        id = 201904,
        albumPath = "GameModule.Card.season201904.CardAlbumView",
        seasonPath = "GameModule.Card.season201904.CardSeason"
    },
    ["202101"] = {
        id = 202101,
        albumPath = "GameModule.Card.season202101.CardAlbumView",
        seasonPath = "GameModule.Card.season202101.CardSeason"
    },
    ["202102"] = {
        id = 202102,
        albumPath = "GameModule.Card.season202102.CardAlbumView",
        seasonPath = "GameModule.Card.season202102.CardSeason"
    },
    ["202103"] = {
        id = 202103,
        albumPath = "GameModule.Card.season202103.CardAlbumView",
        seasonPath = "GameModule.Card.season202103.CardSeason"
    },
    ["202104"] = {
        id = 202104,
        albumPath = "GameModule.Card.season202104.CardAlbumView",
        seasonPath = "GameModule.Card.season202104.CardSeason"
    },
    ["202201"] = {
        id = 202201,
        albumPath = "GameModule.Card.season202201.CardAlbumView",
        seasonPath = "GameModule.Card.season202201.CardSeason"
    },
    ["202202"] = {
        id = 202202,
        albumPath = "GameModule.Card.season202202.CardAlbumView",
        seasonPath = "GameModule.Card.season202202.CardSeason"
    },
    ["202203"] = {
        id = 202203,
        albumPath = "GameModule.Card.season202203.CardAlbumView",
        seasonPath = "GameModule.Card.season202203.CardSeason"
    },
    ["202204"] = {
        id = 202204,
        albumPath = "GameModule.Card.season202204.CardAlbumView",
        seasonPath = "GameModule.Card.season202204.CardSeason"
    },
    ["202301"] = {
        id = 202301,
        albumPath = "GameModule.Card.season202301.CardAlbumView",
        seasonPath = "GameModule.Card.season202301.CardSeason"
    },
    ["202302"] = {
        id = 202302,
        albumPath = "GameModule.Card.season202302.CardAlbumView",
        seasonPath = "GameModule.Card.season202302.CardSeason"
    },
    ["202303"] = {
        id = 202303,
        albumPath = "GameModule.Card.season202303.CardAlbumView",
        seasonPath = "GameModule.Card.season202303.CardSeason"
    },
    ["202304"] = {
        id = 202304,
        albumPath = "GameModule.Card.season202304.CardAlbumView",
        seasonPath = "GameModule.Card.season202304.CardSeason"
    },
    ["202401"] = {
        id = 202401,
        albumPath = "GameModule.Card.season202401.CardAlbumView",
        seasonPath = "GameModule.Card.season202401.CardSeason"
    }
}

-- TODO:新赛季时必加表
CardSysConfigs.TAB_CONFIG = {
    [1] = {
        year = 2019, -- 服务器数据中年度
        tabText = "2020", -- 界面上显示的年度（显示有可能跟服务器的不一样，所以加这个字段）
        albums = {
            -- 赛季列表
            [1] = {tabText = "2020 1ST", albumId = 201901, round = 3}, -- albumId：赛季id（有可能当前年度包含其他年度的赛季，所以加这个字段方便扩展）
            [2] = {tabText = "2020 2ND", albumId = 201902, round = 3},
            [3] = {tabText = "2020 3RD", albumId = 201903, round = 3},
            [4] = {tabText = "2020 4TH", albumId = 201904, round = 3}
        }
    },
    [2] = {
        year = 2021,
        tabText = "2021",
        albums = {
            [1] = {tabText = "2021 1ST", albumId = 202101, round = 3},
            [2] = {tabText = "2021 2ND", albumId = 202102, round = 3},
            [3] = {tabText = "2021 3RD", albumId = 202103, round = 3},
            [4] = {tabText = "2021 4TH", albumId = 202104, round = 3}
        }
    },
    [3] = {
        year = 2022,
        tabText = "2022",
        albums = {
            [1] = {tabText = "2022 1ST", albumId = 202201, round = 3},
            [2] = {tabText = "2022 2ND", albumId = 202202, round = 3},
            [3] = {tabText = "2022 3RD", albumId = 202203, round = 3},
            [4] = {tabText = "2022 4TH", albumId = 202204, round = 3}
        }
    },
    [4] = {
        year = 2023,
        tabText = "2023",
        albums = {
            [1] = {tabText = "2023 1ST", albumId = 202301, round = 3},
            [2] = {tabText = "2023 2ND", albumId = 202302, round = 3},
            [3] = {tabText = "2023 3RD", albumId = 202303, round = 3},
            [4] = {tabText = "2023 4TH", albumId = 202304, round = 3}
        }
    },
    [5] = {
        year = 2024,
        tabText = "2024",
        albums = {
            [1] = {tabText = "2024 1ST", albumId = 202401, round = 3},
        }
    },
    [6] = {
        year = 3023,
        tabText = "3023",
        albums = {
            [1] = {tabText = "3023 1ST", albumId = 302301, round = 1}
        }
    }
}
