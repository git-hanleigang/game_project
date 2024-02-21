-- 定义一些卡片相关的变量
local ScratchWinnerCardConfig = {}

-- 所有类型的卡片 扩展新卡片时不要修改老卡片的名称
ScratchWinnerCardConfig.CardList = {
    {
        order    = 1,                                              -- 顺序
        name     = "triple",                                       -- 卡片名称(服务器使用)
        cardCellRes  = "ScratchWinner_triplejackpot_entrance.csb",                        -- 资源名称
        cardCellCode = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerBaseCard", -- 代码路径
        cardSpine = "ScratchWinner_triplejackpot_entrance",                               -- 卡片的spine资源
        cardViewRes  = "ScratchWinner_triplejackpot.csb",                                        -- 资源名称
        cardViewCode  = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewTriple", -- 代码路径
        cardViewExportSize   = cc.size(690, 955),                                              -- 卡片在出卡口界面时的尺寸(做位移动作用的)(动效说先注释掉程序的动作,用他们的效果.这个效果可以放在以后的刮刮卡用)
        cardViewMaskRes  = "ScratchWinnerCommon/ScratchWinner_Ka1_2.png",                      -- 涂层遮罩
        cardViewMaskRectSize = cc.size(200, 150),                                              -- 涂层大矩阵的尺寸
        cardViewBrushRadius  = 60,                                                             -- 笔刷的半径
        cardViewAutoScrapeInter = 0.0075,                                                      -- 自动刮卡时的移动间隔(影响自动刮卡完成的时间)
    },
    {
        order   = 2,
        name    = "lotto",      
        cardCellRes = "ScratchWinner_lottoluck_entrance.csb",
        cardCellCode = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerBaseCard",
        cardSpine = "ScratchWinner_lottoluck_entrance",
        cardViewRes  = "ScratchWinner_lottoluck.csb",                                          
        cardViewCode  = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewLotto",
        cardViewExportSize   = cc.size(690, 955),
        cardViewMaskRes  = "ScratchWinnerUi/ScratchWinner_Ka2_4.png",    
        cardViewMaskRectSize  = cc.size(160, 140),   
        cardViewBrushRadius  = 50, 
        cardViewAutoScrapeInter = 0.015,                                                    
    },
    {
        order   = 3,
        name    = "bingo",      
        cardCellRes = "ScratchWinner_luckyball_entrance.csb",
        cardCellCode = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerBaseCard",
        cardSpine = "ScratchWinner_luckyball_entrance",
        cardViewRes  = "ScratchWinner_luckyball.csb",    
        cardViewExportSize   = cc.size(690, 1100),                                      
        cardViewCode  = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardViewBingo",
        cardViewMaskRes  = "ScratchWinnerUi/ScratchWinner_Ka3_2.png",  
        cardViewMaskRectSize  = cc.size(200, 150),
        cardViewBrushRadius  = 50,
        cardViewAutoScrapeInter = 0.015,
    },





    {
        order   = 999,
        name    = "commingSoon",      
        cardCellRes = "ScratchWinner_comingsoon_entrance.csb",
        cardCellCode = "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerBaseCard",
        cardSpine = "ScratchWinner_kongbail_entrance",
        cardViewExportSize   = cc.size(100, 100),
        cardViewRes  = "",                                          
        cardViewCode  = "",
        cardViewMaskRes  = "",  
        cardViewMaskRectSize  = cc.size(0, 0),
        cardViewBrushRadius  = 1,
        cardViewAutoScrapeInter = 0.015,
    },
}

return ScratchWinnerCardConfig