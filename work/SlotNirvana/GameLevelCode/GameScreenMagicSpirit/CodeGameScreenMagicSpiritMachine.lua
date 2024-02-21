-- 
-- 玩法：
-- 
-- CodeGameScreenMagicSpiritMachine.lua

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SendDataManager = require "network.SendDataManager"
local CodeGameScreenMagicSpiritMachine = class("CodeGameScreenMagicSpiritMachine", BaseNewReelMachine)

CodeGameScreenMagicSpiritMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1 = 94 -- 绿
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2 = 95 -- 红
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3 = 96 -- 金

--classic1 轮盘内 图标类型    
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_WILD = 192
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_777 = 100
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_77 = 101
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_7 = 102
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_2 = 103
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_1 = 104
--classic2 轮盘内 图标类型
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_WILD = 292
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_777 = 200
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_77 = 201
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_7 = 202
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_2 = 203
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_1 = 204
--classic3 轮盘内 图标类型
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1 = 390
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2 = 391
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3 = 392
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_777 = 300
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_77 = 301
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_7 = 302
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_2 = 303
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_1 = 304
--classic公用的图标类型
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid = 194
CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Blank = 195

CodeGameScreenMagicSpiritMachine.SYMBOL_RS_SCORE_BLANK = 666


CodeGameScreenMagicSpiritMachine.m_chipList = nil
CodeGameScreenMagicSpiritMachine.m_playAnimIndex = 0
CodeGameScreenMagicSpiritMachine.m_lightScore = 0 -- 构造函数

CodeGameScreenMagicSpiritMachine.m_NormalSymbolMul = 1
CodeGameScreenMagicSpiritMachine.m_OutLines = nil

CodeGameScreenMagicSpiritMachine.m_bonusEffectData  = nil       -- 存储正常触发或断线重连的bonus游戏事件数据

--小轮盘信号值对应轮盘索引
CodeGameScreenMagicSpiritMachine.m_classicIndexLis = {
    [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1] = 1,
    [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2] = 2,
    [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3] = 3,
}
----==小滚轮最终结果 对应赢钱线展示,wild逻辑接口内处理
-- 1    2    3    4    5     6      7        8         9         10       11      12          13   
-- 337  327  317  32Br Any37 31bar  Any3Bar  4scatter  3scatter  3wildlv  3wildzi 3wildhuang  Any3wild
CodeGameScreenMagicSpiritMachine.m_classicWinIndexList = {
    -- [1] = {
    --     check = 1,       --检测类型 
                            -- 1:'最终结果列表'包含数量大于配置表内限制数量的同类型信号小块, 
                            -- 2:'最终结果列表'所有类型小块都在配置表内 
                            -- 3:'小轮盘2,3,4行的列表'包含数量等于配置表内限制数量的同类型信号小块
    --     checkCount = 3,   --检测数量 check == 1时 使用
    --     checkWild = true, --检测时使用wild代替
    --     symbolType = {    
    --         [1] = {          --小轮盘类型 1
    --             CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_777,
    --         },
    --         [2] = {          --小轮盘类型 2
    --             CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_777,
    --         },
    --         [3] = {          --小轮盘类型 3
    --             CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_777,
    --         },
    --     },
    -- },
    [1] = {
        check = 1,
        checkCount = 3,
        checkWild = true,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_777,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_777,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_777,},
        },
    },
    [2] = {
        check = 1,
        checkCount = 3,
        checkWild = true,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_77,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_77,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_77,},
        }
    },
    [3] = {
        check = 1,
        checkCount = 3,
        checkWild = true,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_7,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_7,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_7,},
        }
    },
    [4] = {
        check = 1,
        checkCount = 3,
        checkWild = true,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_2,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_2,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_2,},
        }
    },
    [5] = {
        check = 2,
        checkWild = true,
        symbolType = {
            [1] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_777, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_77, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_7,
            },
            [2] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_777, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_77, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_7,
            },
            [3] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_777, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_77, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_7,
            },  
        }
    },
    [6] = {
        check = 1,
        checkCount = 3,
        checkWild = true,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_1,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_1,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_1,},
        }
    },
    [7] = {
        check = 2,
        checkWild = true,
        symbolType = {
            [1] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_2, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_BAR_1, 
            },
            [2] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_2, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_BAR_1, 
            },
            [3] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_2, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_BAR_1, 
            },
        }
    },
    [8] = {
        check = 3,
        checkCount = 4,
        checkWild = false,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
        }
    },
    [9] = {
        check = 3,
        checkCount = 3,
        checkWild = false,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC_SCORE_Rapid,},
        }
    },
    [10] = {
        check = 1,
        checkCount = 3,
        checkWild = false,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1,},
        }
    },
    [11] = {
        check = 1,
        checkCount = 3,
        checkWild = false,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2,},
        }
    },
    [12] = {
        check = 1,
        checkCount = 3,
        checkWild = false,
        symbolType = {
            [1] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3,},
            [2] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3,},
            [3] = {CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3,},
        }
    },
    [13] = {
        check = 2,
        checkWild = false,
        symbolType = {
            [1] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_WILD,
            },
            [2] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_WILD, 
            },
            [3] = {
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2, 
                CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3,
            },  
        }
    },
}
--每种小轮盘使用的wind
CodeGameScreenMagicSpiritMachine.m_classicWildList = {
    [1] = {
        [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC1_SCORE_WILD] = true,
    },
    [2] = {
        [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC2_SCORE_WILD] = true,
    },
    [3] = {
        [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD1] = true,
        [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD2] = true,
        [CodeGameScreenMagicSpiritMachine.SYMBOL_CLASSIC3_SCORE_WILD3] = true,
    },
}
--paytable 倍率  两个  模式下paytable倍率 一致 先使用相同倍率表
CodeGameScreenMagicSpiritMachine.PaytableMultiply = {
     --baseBonus
    [1] = {   
        [1] =  {
            --  节点索引  = 倍率
            [13] = 5000,
            [1] = 1250,
            [2] = 750,
            [3] = 500,
            [4] = 400,
            [5] = 225,
            [6] = 225,
            [7] = 75,
            [8] = 225,
            [9] = 75
        },
        [2] =  {
            [13] = 5000,
            [1] = 1250,
            [2] = 750,
            [3] = 500,
            [4] = 400,
            [5] = 225,
            [6] = 225,
            [7] = 75,
            [8] = 225,
            [9] = 75
        },
        [3] =  {           
            [1] = 1000,
            [2] = 600,
            [3] = 450,
            [4] = 300,
            [5] = 150,
            [6] = 150,
            [7] = 75,
            [8] = 225,
            [9] = 75,
            [10] = 25000,
            [11] = 12000,
            [12] = 8000,
            [13] = 4000,
        },
    },
    --reSpinBonus
    -- [2] = {    
    --     [1] =  {
    --         --  节点索引  = 倍率
    --         [13] = 5000,
    --         [1] = 1250,
    --         [2] = 750,
    --         [3] = 500,
    --         [4] = 400,
    --         [5] = 225,
    --         [6] = 225,
    --         [7] = 75,
    --         [8] = 225,
    --         [9] = 75
    --     },
    --     [2] =  {
    --         [13] = 5000,
    --         [1] = 1250,
    --         [2] = 750,
    --         [3] = 500,
    --         [4] = 400,
    --         [5] = 225,
    --         [6] = 225,
    --         [7] = 75,
    --         [8] = 225,
    --         [9] = 75
    --     },
    --     [3] =  {           
    --         [1] = 1000,
    --         [2] = 600,
    --         [3] = 450,
    --         [4] = 300,
    --         [5] = 150,
    --         [6] = 150,
    --         [7] = 75,
    --         [8] = 225,
    --         [9] = 75,
    --         [10] = 25000,
    --         [11] = 12000,
    --         [12] = 8000,
    --         [13] = 4000,
    --     },
    -- }
}

--重写快滚判断 设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}
--[[
    @desc:  定义的数据类型 及结构 
    self.m_runSpinResultData.p_selfMakeData.leftPositions   --玩家触发进入bonus respin时玩家可进行classic 的数据 里面存着位置 及信号块类型 
    self.m_initFeatureData.p_data.selfData.leftPositions    --bonus 玩法玩家中途离开 断线重连后剩余可进行classic 次数
    self.m_runSpinResultData.p_selfMakeData.wicks --respin内玩家收集的bonus头像个数
    self.m_runSpinResultData.p_selfMakeData.multiplies --base下对应的小块附带的成倍
]]



-- 构造函数
function CodeGameScreenMagicSpiritMachine:ctor()
    CodeGameScreenMagicSpiritMachine.super.ctor(self)

    self.m_EFFECT_BONUS = GameEffect.EFFECT_BONUS
    GameEffect.EFFECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 1 -- 特殊处理本关bonus当成一个自定义游戏事件处理

    self.m_isFeatureOverBigWinInFree = true
    self.m_randomSymbolSwitch = true
    self.isInBonus = false
    self.m_spinRestMusicBG = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_OutLines = true
    self.m_bonusEffectData  = nil

    self.m_bonusLeftPos = {}     --滚动的bonus数据
    self.m_bonusPlayNum = 0      --bonus播放数量

    --reSpin结束时是否全满
    self.m_reSpinIsAll = false
    --上次弹出的paytable类型存一下
    self.m_lastPaytableType = {
        [1] = 0,   --base
        [2] = 0,   --reSpin
    }   
    --reSpin 播放音效的索引
    self.m_respinSoundId = 0

    --是否需要播放中奖预告 ,用于阻止快滚
    self.m_isPlayWinningNotice = false
    --是否是首次快滚 用于角色spine播放。 每次开始滚动都会置为 true
    self.m_isFirstQuickRun = false
    --base模式的bonus玩法是否已经播放过赢钱了
    self.m_baseBonusUpdateWinCoin = false

    self:initGame()
end

function CodeGameScreenMagicSpiritMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MagicSpiritConfig.csv", "LevelMagicSpiritConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  



function CodeGameScreenMagicSpiritMachine:initUI()

    self.m_baseReSpinBar = util_createView("CodeMagicSpiritSrc.MagicSpiritRespinBarView")
    self:findChild("Node_respin_left"):addChild(self.m_baseReSpinBar)
    self.m_reSpinBar_di = self:findChild("MagicSpirit_FREE_CISHU_DI_10")
    self.m_baseReSpinBar:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_baseReSpinBar, true)
    util_setCascadeOpacityEnabledRescursion(self.m_reSpinBar_di, true)

    self.m_JackPotBar = util_createView("CodeMagicSpiritSrc.MagicSpiritJackPotBarView")
    self.m_JackPotBar:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_JackPotBar)

    self.m_JackPotRsBar = util_createView("CodeMagicSpiritSrc.MagicSpiritRsJackPotBarView")
    self.m_JackPotRsBar:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_JackPotRsBar)
    self.m_JackPotRsBar:setVisible(false)

    self.m_respinCollect = util_createView("CodeMagicSpiritSrc.MagicSpiritRespinCollectView",{machine = self})
    self:findChild("Node_jindutiao"):addChild(self.m_respinCollect)
    self.m_respinCollect:setVisible(false)
   
    self.m_tipLab = util_createAnimation("MagicSpirit_tishi.csb")
    self:findChild("Node_tishi"):addChild(self.m_tipLab)
    self.m_tipLab:runCsbAction("auto1",true)
    
    self.m_guoChang = util_spineCreate("MagicSpirit_guochang",true,true)
    self:addChild(self.m_guoChang,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5)
    self.m_guoChang:setPosition(display.width/2,display.height/2)
    self.m_guoChang:setVisible(false)


    self.m_BasePayTable = util_createAnimation("MagicSpirit_xiaopt.csb")
    self:findChild("paytable_1"):addChild(self.m_BasePayTable)
    self.m_BasePayTable:setVisible(false)


    self.m_ResPayTable = util_createAnimation("MagicSpirit_xiaopt_rs.csb")
    self:findChild("paytable_rs"):addChild(self.m_ResPayTable)
    self.m_ResPayTable:setVisible(false)
    
    self.m_bgSpine = util_spineCreate("MagicSpirit_BJ_Leaves",true,true)
    self.m_gameBg:findChild("Node_1"):addChild(self.m_bgSpine)

    self:changeBgShow( )

    self.m_rsFullLock = util_createAnimation("MagicSpirit_respin_FullLock_2X.csb")
    self:findChild("Node_RsFullLock"):addChild(self.m_rsFullLock)
    self.m_rsFullLock:setVisible(false)

    self.m_rsDark = util_createAnimation("MagicSpirit_respin_Dark.csb")
    self:findChild("Panel_dark"):addChild(self.m_rsDark)
    self.m_rsDark:setVisible(false)
    
    --配合角色动画的其他节点层级 bg -> jackpot,jindutiao -> 角色spine
    self:findChild("bg"):setLocalZOrder(-10)
    self:findChild("Node_jackpot"):setLocalZOrder(-8)
    self:findChild("Node_jindutiao"):setLocalZOrder(-8)
    
    self.m_genie = util_spineCreate("MagicSpirit_juese",true,true) -- 使用 m_genie 播放大人物动画时只用 playGenieAnim 接口调用否则会有问题
    self:findChild("node_genie"):addChild(self.m_genie)
    self.m_genieWaitNode = cc.Node:create()
    self:addChild(self.m_genieWaitNode) 

    self.m_Anigenie = util_spineCreate("MagicSpirit_juese",true,true) -- 这个大人物用作classic大轮盘的交互动作用 
    self:findChild("classical"):addChild(self.m_Anigenie)
    self.m_Anigenie:setVisible(false)
    self.m_Anigenie:setPosition(3,330)
    --前置层级的spine 角色2 这个大人物用作中奖预告和主棋盘的角色交互 --层级的话 用上面的节点这个
    self.m_spineAheadGenie = util_spineCreate("MagicSpirit_juese2",true,true)
    self:findChild("node_genieAhead"):addChild(self.m_spineAheadGenie)
    self.m_spineAheadGenie:setVisible(false)

    self.m_reSpinMultiple = util_createAnimation("MagicSpirit_respin_2X.csb")
    self:findChild("Node_MagicSpirit_respin_2X"):addChild(self.m_reSpinMultiple)
    self.m_reSpinMultiple:setVisible(false)

    self.m_reSpinMask = util_createAnimation("MagicSpirit_rs_zhezhao.csb")
    self:findChild("Node_RsFullLock"):addChild(self.m_reSpinMask)
    self.m_reSpinMask:setVisible(false)

    self:playGenieIdle( )

    --点击事件
    self:addClick(self:findChild("spineClick"))

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end
        local soundName = "MagicSpiritSounds/music_MagicSpirit_last_win_".. soundIndex .. ".mp3"

        if globalData.slotRunData.currSpinMode < FREE_SPIN_MODE and winRate > 1 then
            soundName = string.format("MagicSpiritSounds/music_MagicSpirit_baseLast_win_%d.mp3", math.random(2, 3)) 
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenMagicSpiritMachine:playGenieAnim(_aniName,_loop,_time,_func )
    local aniName,loop,time,func = _aniName,_loop,_time,_func
    self.m_genieWaitNode:stopAllActions()
    util_spinePlay(self.m_genie,aniName,loop)
    if not loop then
        if time and func then
            performWithDelay(self.m_genieWaitNode,function(  )
                if func then
                    func()
                end
            end,time)
        end
    end
end

function CodeGameScreenMagicSpiritMachine:playGenieIdle( )

    self.m_genieWaitNode:stopAllActions()
    self:playGenieIdleAnim( )

end

function CodeGameScreenMagicSpiritMachine:playGenieIdleAnim( )
    
    util_spinePlay(self.m_genie,"idleframe",true)
    performWithDelay(self.m_genieWaitNode,function(  )
        local rod = math.random(1,4) -- 百分之25的概率播其中一条
        if rod == 1 then
            rod = math.random(1,3) 
            if rod == 1 then
                
                util_spinePlay(self.m_genie,"idleframe2")
                performWithDelay(self.m_genieWaitNode,function(  )
                    self:playGenieIdleAnim( )
                end,90/30)
            elseif rod == 2 then
                util_spinePlay(self.m_genie,"idleframe3")
                performWithDelay(self.m_genieWaitNode,function(  )
                    self:playGenieIdleAnim( )
                end,105/30)
            elseif rod == 3 then
                util_spinePlay(self.m_genie,"idleframe4")
                performWithDelay(self.m_genieWaitNode,function(  )
                    self:playGenieIdleAnim( )
                end,60/30)
            end
        else
            self:playGenieIdleAnim()
        end

    end,90/30)
    
end


function CodeGameScreenMagicSpiritMachine:playRsGenieIdle( )

    self.m_genieWaitNode:stopAllActions()
    self:playRsGenieIdleAnim( )

end

function CodeGameScreenMagicSpiritMachine:playRsGenieIdleAnim( )
    
    util_spinePlay(self.m_genie,"idleframe7",true)
    --摇摆音效
    performWithDelay(self.m_genieWaitNode,function()
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_run.mp3")
    end, 435/30)

    performWithDelay(self.m_genieWaitNode,function(  )
        -- local rod = math.random(1,4) -- 百分之25的概率播其中一条
        -- if rod == 1 then
        --     rod = math.random(1,2) 
        --     if rod == 1 then
        --         util_spinePlay(self.m_genie,"idleframe5")
        --         performWithDelay(self.m_genieWaitNode,function(  )
        --             self:playRsGenieIdleAnim( )
        --         end,50/30)
        --     elseif rod == 2 then
        --         util_spinePlay(self.m_genie,"idleframe6")
        --         performWithDelay(self.m_genieWaitNode,function(  )
        --             self:playRsGenieIdleAnim( )
        --         end,70/30)
        --     end
        -- else
            self:playRsGenieIdleAnim()
        -- end

    end,900/30)
    
end

function CodeGameScreenMagicSpiritMachine:changeBgShow( _isRs)
    
    self.m_gameBg:findChild("Respin"):setVisible(false)
    self.m_gameBg:findChild("Bace"):setVisible(false)
    self:findChild("respin_bg"):setVisible(false)
    self.m_gameBg:runCsbAction("idle",true)
    
    if _isRs then
        self.m_reSpinBar_di:setVisible(true)

        self:findChild("respin_bg"):setVisible(true)
        self.m_gameBg:findChild("Respin"):setVisible(true)
        util_spinePlay(self.m_bgSpine,"idleframe2",true) -- respin
    else
        self.m_gameBg:findChild("Bace"):setVisible(true)
        util_spinePlay(self.m_bgSpine,"idleframe1",true) -- base
    end

end

function CodeGameScreenMagicSpiritMachine:changeJackpotBarShow(_isRs, playAnim)
    if(playAnim)then
        self.m_JackPotBar:runCsbAction("switch", false, function()
            self.m_JackPotBar:setVisible(not _isRs)
        end)
        self.m_JackPotRsBar:runCsbAction("switch", false, function()
            self.m_JackPotRsBar:setVisible(_isRs)

            if _isRs then
                self.m_JackPotRsBar:runCsbAction("idle", true)
            end
        end)
    else
        self.m_JackPotBar:setVisible(not _isRs)
        self.m_JackPotRsBar:setVisible(_isRs)
    end
end
-- 断线重连 
function CodeGameScreenMagicSpiritMachine:MachineRule_initGame(  )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    


    --更新grand赢钱
    local grandValue = selfData.jackpotWinCoins or 0
    if grandValue > 0 then
        local beiginCoins = grandValue
        local endCoins = grandValue
        local isNotifyUpdateTop = false
        local playWinSound = nil
        self:updateBottomUICoins( beiginCoins,endCoins,isNotifyUpdateTop,playWinSound )
    end
    
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMagicSpiritMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "MagicSpirit"  
end

-- 继承底层respinView
function CodeGameScreenMagicSpiritMachine:getRespinView()
    return "CodeMagicSpiritSrc.MagicSpiritRespinView"
end
-- 继承底层respinNode
function CodeGameScreenMagicSpiritMachine:getRespinNode()
    return "CodeMagicSpiritSrc.MagicSpiritRespinNode"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMagicSpiritMachine:MachineRule_GetSelfCCBName(symbolType)
    
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if      symbolType == self.SYMBOL_CLASSIC1              then
        return "Socre_MagicSpirit_Wheel_1"
    elseif  symbolType == self.SYMBOL_CLASSIC2              then
        return "Socre_MagicSpirit_Wheel_2"
    elseif  symbolType == self.SYMBOL_CLASSIC3              then
        return "Socre_MagicSpirit_Wheel_3"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_WILD   then
        return "Socre_MagicSpirit_Classical1_wild"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_777    then
        return "Socre_MagicSpirit_Classical1_777"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_77     then
        return "Socre_MagicSpirit_Classical1_77"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_7      then
        return "Socre_MagicSpirit_Classical1_7"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_BAR_2  then
        return "Socre_MagicSpirit_Classical_2bar"
    elseif  symbolType == self.SYMBOL_CLASSIC1_SCORE_BAR_1  then
        return "Socre_MagicSpirit_Classical_bar"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_WILD   then
        return "Socre_MagicSpirit_Classical2_wild"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_777    then
        return "Socre_MagicSpirit_Classical2_777"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_77     then
        return "Socre_MagicSpirit_Classical2_77"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_7      then
        return "Socre_MagicSpirit_Classical2_7"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_BAR_2  then
        return "Socre_MagicSpirit_Classical_2bar"
    elseif  symbolType == self.SYMBOL_CLASSIC2_SCORE_BAR_1  then
        return "Socre_MagicSpirit_Classical_bar"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_WILD1  then
        return "Socre_MagicSpirit_Classical3_wild1"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_WILD2  then
        return "Socre_MagicSpirit_Classical3_wild2"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_WILD3  then
        return "Socre_MagicSpirit_Classical3_wild3"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_777    then
        return "Socre_MagicSpirit_Classical3_777"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_77     then
        return "Socre_MagicSpirit_Classical3_77"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_7      then
        return "Socre_MagicSpirit_Classical3_7"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_BAR_2  then
        return "Socre_MagicSpirit_Classical_2bar"
    elseif  symbolType == self.SYMBOL_CLASSIC3_SCORE_BAR_1  then
        return "Socre_MagicSpirit_Classical_bar"
    elseif  symbolType == self.SYMBOL_CLASSIC_SCORE_Rapid   then
        return "Socre_MagicSpirit_Classic_jackpot"
    elseif  symbolType == self.SYMBOL_CLASSIC_SCORE_Blank   then
        return "Socre_MagicSpirit_Classical_Blank"
    elseif  symbolType == self.SYMBOL_RS_SCORE_BLANK   then
        return "Socre_MagicSpirit_Rs_di"
    end



    return nil
end


-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenMagicSpiritMachine:getReSpinSymbolScore(id)
     -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
     local storedIcons = self.m_runSpinResultData.p_storedIcons
     local score = nil
     local idNode = nil
 
     for i = 1, #storedIcons do
         local values = storedIcons[i]
         if values[1] == id then
             score = values[2]
             idNode = values[1]
         end
     end
 
     if score == nil then
         return 0
     end
 
     local pos = self:getRowAndColByPos(idNode)
     local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)
 
     return score
end

function CodeGameScreenMagicSpiritMachine:randomDownSymbolMul(_symbolType)
    -- 根据配置表来获取滚动时 respinBonus小块的分数
    -- 配置在 Cvs_cofing 里面

    local mul = self.m_configData:getFixSymbolPro(_symbolType)

    return mul or 2
end

-- 给respin小块进行赋值
function CodeGameScreenMagicSpiritMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    -- 把idleframe 注释掉,会把reSpin的buling 打断
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then

        --根据网络数据获取停止滚动时小块倍数
        local mul = self:getNormalSymbolMul(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if type(mul) == "number" then
            if mul > self.m_NormalSymbolMul then
                self:createBaseReelMulLab(symbolNode )
                self:setMulLabNum(mul,symbolNode)
            end
        end
        -- symbolNode:runAnim("idleframe")
    else
        local mul = self:randomDownSymbolMul(symbolType) --获取分数（随机假滚数据）
        if symbolNode and symbolNode.p_symbolType then
            if mul ~= nil and type(mul) ~= "string" then
                if type(mul) == "number" then
                    if mul > self.m_NormalSymbolMul then
                        if not self.m_OutLines then
                            self:createBaseReelMulLab(symbolNode )
                            self:setMulLabNum(mul,symbolNode)
                        end
                    end
                end
            end
            -- symbolNode:runAnim("idleframe")
        end
    end

end




-- 根据网络数据获得普通小块的倍数
function CodeGameScreenMagicSpiritMachine:getNormalSymbolMul(_posId)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local multiplies = selfdata.multiplies or {}
    local mul = self.m_NormalSymbolMul
    if _posId then
        local index = _posId + 1
        mul = multiplies[index]  or 1
    end
   
    return mul
end


function CodeGameScreenMagicSpiritMachine:createBaseReelMulLab(_symbolNode )
    local mulLab = util_createAnimation("MagicSpirit_multi.csb") 
    _symbolNode:addChild(mulLab,300)
    mulLab:setPosition(42,-32)
    mulLab:setName("mulLab")
end

function CodeGameScreenMagicSpiritMachine:removeBaseReelMulLab(_symbolNode )
    local mulLab = _symbolNode:getChildByName("mulLab")
    if mulLab then
        mulLab:removeFromParent()
    end
end

function CodeGameScreenMagicSpiritMachine:setMulLabNum(num,_symbolNode)
    local mulLab = _symbolNode:getChildByName("mulLab")
    if mulLab then
        local lab2 = mulLab:findChild("2X")
        local lab3 = mulLab:findChild("3X")
        local lab5 = mulLab:findChild("5X")

        local lab2_di = mulLab:findChild("2X2")
        local lab3_di = mulLab:findChild("3X2")
        local lab5_di = mulLab:findChild("5X2")

        if lab2 and lab3 and lab5 then
            lab2:setVisible( num == 2 )
            lab3:setVisible( num == 3 )
            lab5:setVisible( num == 5 )
        end
        if lab2_di and lab3_di and lab5_di then
            lab2_di:setVisible( num == 2 )
            lab3_di:setVisible( num == 3 )
            lab5_di:setVisible( num == 5 )
        end

    end
end

function CodeGameScreenMagicSpiritMachine:pushSlotNodeToPoolBySymobolType(symbolType, gridNode)
    self:removeBaseReelMulLab(gridNode )
    CodeGameScreenMagicSpiritMachine.super.pushSlotNodeToPoolBySymobolType(self,symbolType, gridNode)
    
end

function CodeGameScreenMagicSpiritMachine:checkAddMuilLab(_symbolType )
    if self:isFixSymbol(_symbolType) or 
        self.SYMBOL_CLASSIC_SCORE_Rapid == _symbolType or
            self.SYMBOL_CLASSIC_SCORE_Blank == _symbolType  then

        return false
    else
        return true
    end
end

function CodeGameScreenMagicSpiritMachine:updateReelGridNode(_symbolNode)

    local symbolType = _symbolNode.p_symbolType
    if symbolType then

        self:removeClassicWinView(_symbolNode )
        
        self:removeBaseReelMulLab(_symbolNode )
        if self:checkAddMuilLab(symbolType )  then
            self:setSpecialNodeScore(nil, {_symbolNode})
        end
        
    end
end


----------------------------- 玩法处理 -----------------------------------

-- 是不是 respinBonus小块
function CodeGameScreenMagicSpiritMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_CLASSIC1 
        or symbolType == self.SYMBOL_CLASSIC2 
            or symbolType == self.SYMBOL_CLASSIC3 then

        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenMagicSpiritMachine:slotOneReelDown(reelCol)    
    CodeGameScreenMagicSpiritMachine.super.slotOneReelDown(self,reelCol) 

    local isplay= true
    if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
        local isHaveFixSymbol = false
        for k = 1, self.m_iReelRowNum do
            if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
                isHaveFixSymbol = true
                break
            end
        end
        if isHaveFixSymbol == true and isplay then
            isplay = false
            -- respinbonus落地音效
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonus_down.mp3")
        end
    end
   

    ---本列是否开始长滚
    local isTriggerLongRun = self:setReelLongRun(reelCol)
     if isTriggerLongRun then
        self:playJueseQuickRunAnim(reelCol)
    end
    

end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenMagicSpiritMachine:levelFreeSpinEffectChange()

    
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenMagicSpiritMachine:levelFreeSpinOverChangeEffect()

    
    
end

--[[
    
****************** respin相关  ******************
--]]
function CodeGameScreenMagicSpiritMachine:showRespinJackpot(num,coins,func)
    

    local index = 5
    if num == 9 then
        index = 1
    elseif num == 8 then
        index = 2
    elseif num == 7 then
        index = 3
    elseif num == 6 then
        index = 4
    elseif num == 5 then
        index = 5
    end

    local jackPotWinView = util_createView("CodeMagicSpiritSrc.MagicSpiritJackPotWinView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_JackpotView_Diamond.mp3")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index, coins, func)
end

-- 结束respin收集
function CodeGameScreenMagicSpiritMachine:playLightEffectEnd()

    -- 通知respin结束
    self:respinOver()
end

function CodeGameScreenMagicSpiritMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        -- 此处跳出递归

        --所有小块滚动完毕 判断X2动效播放
        self:playMultipleFly(function()
            self:playLightEffectEnd()
        end)

        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    local addScore = 0

    self.m_lightScore = self.m_lightScore + addScore

    --bonus结算延时
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        self:showRespinClassicSlot(function(  )

            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim() 
    
        end)

        waitNode:removeFromParent()
    end, 0.5)
end



--结束移除小块调用结算特效
function CodeGameScreenMagicSpiritMachine:reSpinEndAction()    
    
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- self:clearCurMusicBg()--reSpin结束 还有bonus玩法不停止音乐
    --隐藏最后一个小块全满提示
    self.m_respinView:changeLastOneAnimTipVisible(false)

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()  
    --是否全满
    self.m_reSpinIsAll = #self.m_chipList >=  self.m_iReelColumnNum * self.m_iReelRowNum

    --开始滚动轮盘内的所有固定小轮盘
    local CallFun = function()
        --排序:绿->红->金
        table.sort(
            self.m_chipList,
            function(a, b)
                if(a.p_symbolType ~= b.p_symbolType)then
                    return a.p_symbolType < b.p_symbolType
                elseif(a.p_cloumnIndex ~= b.p_cloumnIndex)then
                    return a.p_cloumnIndex < b.p_cloumnIndex
                end

                return a.p_rowIndex > b.p_rowIndex
            end
        )
        --开始bonus玩法禁止人物点击
        self:setSpineClickState(false)
        --开始单独滚动固定小块
        self:playChipCollectAnim()
    end

    
    
    self:respinOverPlayJpChange( function(  )
        
           
        if self:isCollectTriggerJackpot() then
            -- respin收集只有收集>= 10 个才会走到这一步
            
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local jackpotWinCoins = selfdata.jackpotWinCoins

            -- 当respin收集满的时候进行操作
            if CallFun then
                CallFun()
            end
        else

            if CallFun then
                CallFun()
            end
        end

    end )

end


-- 根据本关卡实际小块数量填写
function CodeGameScreenMagicSpiritMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_RS_SCORE_BLANK,
        TAG_SYMBOL_TYPE.SYMBOL_BONUS,
        self.SYMBOL_CLASSIC1,
        self.SYMBOL_CLASSIC2,
        self.SYMBOL_CLASSIC3
    }
    return symbolList

end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenMagicSpiritMachine:getRespinLockTypes( )
    --落地效果移入代码内 手动在回弹时播放
    local symbolList = {
        {type = self.SYMBOL_CLASSIC1, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_CLASSIC2, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_CLASSIC3, runEndAnimaName = "", bRandom = false}
    }

    return symbolList
end

function CodeGameScreenMagicSpiritMachine:showRespinView()
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        globalMachineController:playBgmAndResume("MagicSpiritSounds/music_MagicSpirit_bonus_tip.mp3",3,0.4)
        --先播放动画 再进入respin
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp  then
                    if self:isFixSymbol(targSp.p_symbolType)  then
                        targSp:runAnim("actionframe")
                    end
                end
            end
        end

        performWithDelay(waitNode,function(  )
            self:playReSpinStartJueseAnim()

            waitNode:removeFromParent()
        end,132/60)
    end,1.5)
        
    
end
--进入reSpin时角色播放动画
function CodeGameScreenMagicSpiritMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    --修改为spine弹板
    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func,BaseDialog.AUTO_TYPE_ONLY)
    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    --第130帧  角色上升
    performWithDelay(waitNode,function(  )
        --播放reSpin背景音乐 同时播放动作
        --角色动画 播放respin大角色idle接口 
        self:playRsGenieIdle()
        if func then
            func()
        end
    end, (17+110)/30)
end
--主界面下潜 -> ReSpin展示 -> 主界面上升
function CodeGameScreenMagicSpiritMachine:playReSpinStartJueseAnim(endFun)
    --播放reSpin过场时 禁止
    self:setSpineClickState(false)

    --音效 reSpin开始
    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_start.mp3") 

    self:playGenieAnim("over", false, 17/30, function()
        --播放时修改挂载节点层级，结束后恢复,已在初始化时将最底层bg节点层级 修改
        local parent = self:findChild("node_genie")
        parent:setLocalZOrder(9999)

        self:playGenieAnim("actionframe8")
        --第20帧 切换背景展示
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            --进入reSpin模式，一些切换展示功能
            self:changeBgShow( true )
            --收集栏
            self:updataCollectNum(true)
            self.m_respinCollect:setVisible(true)
            --reSpin次数栏
            self:changeReSpinBarShow(true)
            self.m_baseReSpinBar:showRespinBar(self.m_runSpinResultData.p_reSpinCurCount)
            --提示
            self.m_tipLab:setVisible(false)
            --清空底栏
            self.m_bottomUI:checkClearWinLabel()
            --构造盘面数据
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
            self:triggerReSpinCallFun(endTypes, randomTypes) 
            --根据数量触发展示
            self.m_respinView:checkBonusCount()
            self.m_respinView:playBonusIdleframe()
            --释放base棋盘的小块csb --drawCall优化
            self:reSpinStartChangeReel()

            --第130帧  角色上升
            performWithDelay(waitNode,function(  )
                parent:setLocalZOrder(-9)
                --播放完毕 恢复
                self:setSpineClickState(true)

                --上升
                -- self:playJueseStartAnimSound()
                self:playGenieAnim("start2", false, 90/30, function()
                    
                    if endFun then
                        endFun()
                    end

                end)
                
                waitNode:removeFromParent()
            end,110/30)
        end,20/30)
    end)
end

--reSpin结算时的遮罩展示
function CodeGameScreenMagicSpiritMachine:changeBonusMaskShow(isShow)
    local actionName = isShow and "start" or "over"
    self.m_reSpinMask:setVisible(false)
    self.m_reSpinMask:runCsbAction(actionName,false,function()
        if not isShow then
            self.m_reSpinMask:setVisible(false)
        end
    end)
end
--reSpin结算时小轮盘上的paytable提示
function CodeGameScreenMagicSpiritMachine:playReSpinPaytableEnter(symbolType)
    
end
--ReSpin开始改变UI状态
function CodeGameScreenMagicSpiritMachine:changeReSpinStartUI(respinCount)
    util_setCsbVisible(self.m_baseReSpinBar, true)
    self.m_baseReSpinBar:showRespinBar(respinCount)
end

--ReSpin刷新数量
function CodeGameScreenMagicSpiritMachine:changeReSpinUpdateUI(curCount)
    self.m_baseReSpinBar:updateLeftCount(curCount, false)
end

--ReSpin结算改变UI状态
function CodeGameScreenMagicSpiritMachine:changeReSpinOverUI()

end

function CodeGameScreenMagicSpiritMachine:showRespinOverView()
    --先淡出paytable 在展示 结束弹板，展示弹板接口已搬运至 triggerRespinOverView
    self:playSmallPaytableOverAction(true, function()
        --时间线1 -> 收集钱 -> 时间线2 -> 结束
        self:triggerRespinOverView()
    end)
end
--
function CodeGameScreenMagicSpiritMachine:triggerRespinOverView()
    --先播时间线1(层级:主棋盘后) 所有小轮盘飞往完毕后 再播时间线2(层级:主棋盘前) -> 结束
    local endFun = function()
        self.m_reSpinMultiple:setVisible(false)
        self:changeJackpotBarShow(false, false)
        self:changeBgShow()
        self.m_tipLab:setVisible(true)
        --人物spine恢复为 base模式 存在大赢的话 改为等待大赢结束播放
        if not self:isHasBigWin() then
            self.m_reSpinOverPlayAnim = false
            --上升
            self:playJueseStartAnimSound()
            self:playGenieAnim("start",false,90/30,function(  )  
                self:playGenieIdle( )
                --结束bonus玩法 恢复
                self:setSpineClickState(true)
            end )
        else
            self.m_reSpinOverPlayAnim = true
        end
        
        --随机展示
        self:reSpinOverChangeReel()

        self:triggerReSpinOverCallFun(self.m_lightScore)

        -- 
        self.m_lightScore = 0
        self:resetMusicBg() 

        --界面关闭回调内会移除节点
        self.m_reSpinOverView = nil
    end

    self:showReSpinOver(function()
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respinOver_guochang.mp3")

        --展示reSpin模式bonus玩法结束过场前，把 服务器赢钱取值修改为reSpin 总赢钱，因为其内可能中le立刻结算的grand
        globalData.slotRunData.lastWinCoin = 0
        self.m_serverWinCoins = self.m_runSpinResultData.p_resWinCoins or self.m_serverWinCoins

        self:showGuoChang(endFun)
    end)
end

function CodeGameScreenMagicSpiritMachine:isHasBigWin()
    local bool = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            
        bool = true
    end

    return bool
end
function CodeGameScreenMagicSpiritMachine:reSpinStartChangeReel()
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            self:removeBaseReelMulLab( _node )
            _node:removeAndPushCcbToPool()
        end
    end)
end
function CodeGameScreenMagicSpiritMachine:reSpinOverChangeReel()
    self:baseReelForeach(function(_node, _iCol, _iRow)
        if _node then
            local cloumnIndex = _node.p_cloumnIndex
            local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex( cloumnIndex )
            local symbolType = self:getRandomReelType(cloumnIndex, reelDatas)
            local ccbName = self:getSymbolCCBNameByType(self, symbolType)
            _node:changeCCBByName(ccbName, symbolType)
            _node:changeSymbolImageByName(ccbName)
            _node:resetReelStatus()
        end
    end)
end
--=====重写reSpinOver弹板接口   
function CodeGameScreenMagicSpiritMachine:showReSpinOver(func)
    self:clearCurMusicBg()

    local parent = self:findChild("Node_ReSpinOver")
    parent:setLocalZOrder(-5)
    if(not self.m_reSpinOverView)then
        self.m_reSpinOverView = util_createView("CodeMagicSpiritSrc.MagicSpiritRespinOverView")
        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_reSpinOverView.getRotateBackScaleFlag = function() return false end
        end

        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonusCollect_start.mp3")
        --挂载在主棋盘上便于修改层级
        parent:addChild(self.m_reSpinOverView)
    end
    
    --初始化参数
    local fun_start1 = function()
        --2.固定位置
        self.m_reSpinOverView:playActionIdle1()
    end
    local fun_idle1 = function()
       self.m_winCoinChipList = self:getAllWinCoinCleaningNode(self.m_chipList)

        --3.收集结束
        self:reSpinBonusOverChangeTopVisible(false)
        self:playReSpinOverCollectAnim(1, function()
            self:reSpinBonusOverChangeTopVisible(true)
            parent:setLocalZOrder(9999)
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_bonusCollect_big.mp3")
            self.m_reSpinOverView:playActionStart2()
        end)
    end
    local fun_start2 = function()
        --4.高亮展示最终金币
        self.m_reSpinOverView:playActionIdle2()
    end

    local node_genie = self:findChild("node_genie")
    local spineWordPos = node_genie:getParent():convertToWorldSpace(cc.p(node_genie:getPosition()))

    local params = {
        machine = self,

        spineWordPos = spineWordPos,

        fun_start1 = fun_start1,
        fun_idle1 = fun_idle1,
        fun_start2 = fun_start2,

        fun_close = func,
    }
    self.m_reSpinOverView:initViewData(params)


    --1.弹板出现
    self.m_reSpinOverView:playActionStart1()


    return  self.m_reSpinOverView 
end
--reSpin模式bonus结束 修改裁剪节点的 裁剪属性和顶部小块的 可见行
function CodeGameScreenMagicSpiritMachine:reSpinBonusOverChangeTopVisible(isVisible)
    self.m_onceClipNode:setClippingEnabled(isVisible)

    for _iCol=1,self.m_iReelColumnNum do
        local targSp = self:getFixSymbol(_iCol, self.m_iReelRowNum + 1, SYMBOL_NODE_TAG)
        if targSp then
            targSp:setVisible(isVisible)
        end
    end
end
--获取所有赢钱的固定小块
function CodeGameScreenMagicSpiritMachine:getAllWinCoinCleaningNode(chipList)
    --所有赢钱小块
    local winCoinChipList = {}
    for _index,_chipNode in ipairs(chipList) do
        local classicWinView = util_getChildByName(_chipNode, "classicWinView")
        if(classicWinView and classicWinView.m_winCoin > 0)then
            table.insert(winCoinChipList, _chipNode)
        end
    end
    --排序 列->行
    table.sort(
        winCoinChipList,
        function(a, b)
            if(a.p_cloumnIndex ~= b.p_cloumnIndex)then
                return a.p_cloumnIndex < b.p_cloumnIndex
            end

            return a.p_rowIndex > b.p_rowIndex 
        end
    )

    return winCoinChipList
end

-- --重写组织respinData信息
function CodeGameScreenMagicSpiritMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end


---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMagicSpiritMachine:MachineRule_SpinBtnCall()
    
    self.m_OutLines = false
    self:setMaxMusicBGVolume()

    --停掉赢钱音效
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    --日志输出
    local funName = "[CodeGameScreenMagicSpiritMachine:MachineRule_SpinBtnCall]"
    self:magicSpiritReleasePrint(funName)

    return false -- 用作延时点击spin调用
end




function CodeGameScreenMagicSpiritMachine:enterGamePlayMusic(  )
    self:playEnterGameSound( "MagicSpiritSounds/music_MagicSpirit_enterLevel.mp3" )
end

function CodeGameScreenMagicSpiritMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagicSpiritMachine.super.onEnter(self) 	-- 必须调用不予许删除
    self:addObservers()

    self.m_classicMachine = util_createView("CodeMagicSpiritSrc.MagicSpiritClassicSlots", {parent = self})
    self:findChild("classical"):addChild(self.m_classicMachine)
    self.m_classicMachine:restAllReelsNode()
    self.m_classicMachine:runCsbAction("switch")
    self.m_classicMachine:setVisible(false)

    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_classicMachine.m_touchSpinLayer)
    end
 
    
end

function CodeGameScreenMagicSpiritMachine:createClassicWinView(_tarSp )
    local winView = nil

    _tarSp:runAnim("idleframe")
    
    local Node_ClassicWin = _tarSp:getCcbProperty("Node_ClassicWin")
    if Node_ClassicWin then
        winView = util_getChildByName(Node_ClassicWin, "classicWinView")

        if not winView then
            winView = util_createView("CodeMagicSpiritSrc.MagicSpiritClassicWinView",self.m_classicMachine)
            winView:setName("classicWinView")
            Node_ClassicWin:addChild(winView)


        end
    end
    
    local Node_root = _tarSp:getCcbProperty("Node_root")
    if Node_root then
        Node_root:setVisible(false)
    end

    return winView 
end

function CodeGameScreenMagicSpiritMachine:removeClassicWinView(_parentNode )

    if _parentNode and _parentNode.p_symbolType then
        if self:isFixSymbol(_parentNode.p_symbolType) then
            local Node_ClassicWin = _parentNode:getCcbProperty("Node_ClassicWin")
            if Node_ClassicWin then
                Node_ClassicWin:removeAllChildren()
            end
            local Node_root = _parentNode:getCcbProperty("Node_root")
            if Node_root then
                Node_root:setVisible(true)
            end
        end
    end
    

end

function CodeGameScreenMagicSpiritMachine:removeClassicWinViewByAnimNode(_parentNode )
    if _parentNode and _parentNode.p_symbolType then
        if self:isFixSymbol(_parentNode.p_symbolType) then
            local Node_ClassicWin = _parentNode:getCcbProperty("Node_ClassicWin")
            if Node_ClassicWin then
                Node_ClassicWin:removeAllChildren()
            end
            local Node_root = _parentNode:getCcbProperty("Node_root")
            if Node_root then
                Node_root:setVisible(true)
            end
        end
    end
    
end

function CodeGameScreenMagicSpiritMachine:createClassicEffect( bonusSymbol )
    local parent = bonusSymbol:getParent()
    local position = cc.p(bonusSymbol:getPosition())
    local order = bonusSymbol:getLocalZOrder()

    local effect = parent:getChildByName("Socre_MagicSpirit_Wheel_L")
    if not effect then
        effect = util_createAnimation("Socre_MagicSpirit_Wheel_L.csb")
        effect:setName("Socre_MagicSpirit_Wheel_L")
        parent:addChild(effect)
        effect:setVisible(false)
    end
    effect:setLocalZOrder(order-1)
    effect:setPosition(position)

    return effect
end
function CodeGameScreenMagicSpiritMachine:addObservers()
    --reSpin所有小块回弹完毕监听
    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_respinView:checkBonusCount()
            --
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )
    --reSpin按照优先级播放音效 金色机器落地 ＞ 次数回到3
    gLobalNoticManager:addObserver(self,function(self,params)
        self:noticCallBack_playRespinSound(params)
    end,"MagicSpirit_playRespinSound")

    --注册了很多监听？ 新增必须放在此前,且拷贝一下父类的内容
	CodeGameScreenMagicSpiritMachine.super.addObservers(self)  
end

function CodeGameScreenMagicSpiritMachine:onExit()

    GameEffect.EFFECT_BONUS = self.m_EFFECT_BONUS  -- 还原bonuseffect 索引

    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMagicSpiritMachine.super.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

-- reSpin音效 一次spin只能按顺序播放一种音效
function CodeGameScreenMagicSpiritMachine:noticCallBack_playRespinSound(_params)
    local soundId = _params[1]
    if self.m_respinSoundId > 0 and soundId ~= self.m_respinSoundId then
        return
    end


    local index = 1
    --金色机器落地
    if soundId == index then
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_baseLast_win_2.mp3")
        -- gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_goodDown.mp3")
        self.m_respinSoundId = index
        return
    end

    index = index + 1
    --次数回到3
    if soundId == index then
        local soundName = string.format("MagicSpiritSounds/music_MagicSpirit_respin_reset%d.mp3", math.random(1,2))
        gLobalSoundManager:playSound(soundName)
        self.m_respinSoundId = index
        return
    end
end
-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMagicSpiritMachine:addSelfEffect()
        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMagicSpiritMachine:MachineRule_playSelfEffect(effectData)
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMagicSpiritMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


function CodeGameScreenMagicSpiritMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMagicSpiritMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMagicSpiritMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    --播放了快滚动作后，在滚动停止时恢复idle
    if not self.m_isFirstQuickRun then
        self:playGenieAnim("actionframe14",false,32/30,function(  )   
            self:playGenieIdle()
        end )
    end

    self.m_isPlayWinningNotice = false
    --预告中奖音效
    if self.m_noticeSoundId then
        gLobalSoundManager:stopAudio(self.m_noticeSoundId)
        self.m_noticeSoundId = nil
    end


    CodeGameScreenMagicSpiritMachine.super.slotReelDown(self)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenMagicSpiritMachine:operaEffectOver()
    printInfo("run effect end")

    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

    if self.checkControlerReelType and self:checkControlerReelType() then
        globalMachineController.m_isEffectPlaying = false
    end

    -- 结束动画播放
    self.m_isRunningEffect = false

    self.m_autoChooseRepin = self.m_chooseRepin --防止被清空

    self:playEffectNotifyNextSpinCall()

    self:playEffectNotifyChangeSpinStatus()

    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
    -- self:setLastWinCoin(  0) -- 重置累计的金钱。
    end

    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if freeSpinsTotalCount and freeSpinsLeftCount then
        if freeSpinsTotalCount > 0 and freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end

---- lighting 断线重连时，随机转盘数据(重写 底层随机的时候随机了8个信号块而这关只有7个普通信号)
function CodeGameScreenMagicSpiritMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        local storedIcons = self.m_initSpinData.p_storedIcons
        if storedIcons == nil or #storedIcons <= 0 then
            return
        end

        local function isInArry(iRow, iCol)
            for k = 1, #storedIcons do
                local fix = self:getRowAndColByPos(storedIcons[k][1])
                if fix.iX == iRow and fix.iY == iCol then
                    return true
                end
            end
            return false
        end

        for iRow = 1, #self.m_initSpinData.p_reels do
            local rowInfo = self.m_initSpinData.p_reels[iRow]
            for iCol = 1, #rowInfo do
                if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                    rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % self.m_iRandomSmallSymbolTypeNum
                end
            end
        end
    end
end



--[[
    ****************** respin收集bonus图标  ****************** 
]]

-- 判断是否有可收集的Bonus图标
function CodeGameScreenMagicSpiritMachine:getHaveCollectBonusSymbol()
    local reel = self.m_runSpinResultData.p_reels
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = reel[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                return true
            end
        end
    end
    return false
end

---判断结算
function CodeGameScreenMagicSpiritMachine:reSpinReelDown(addNode)

    if self:getHaveCollectBonusSymbol() then
        --从 reSpinReelDown 提出来 落地立刻先刷次数
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )

            self:playCollectBonusEffect(function()
                self:reSpinReelDownMagicSpirit(self,addNode) 
            end)

            waitNode:removeFromParent()
        end,0.5)
        
    else
        self:reSpinReelDownMagicSpirit(self,addNode) 
    end
    
end

function CodeGameScreenMagicSpiritMachine:playCollectBonusEffect(_func)
    local endPos = util_convertToNodeSpace(self.m_respinCollect:getCollectFlyNode(), self)
    local bPlayNext = false

    local chipList = self.m_respinView:getAllCollectNode()
    -- 移除收集精灵的音效播放 21.08.16
    -- local soundName = string.format("MagicSpiritSounds/music_MagicSpirit_respin_collectHead%d.mp3", math.random(1,3))
    -- gLobalSoundManager:playSound(soundName)
    for i = 1, #chipList do
        local chipNode = chipList[i]
        local startPos = util_convertToNodeSpace(chipNode, self)

        --播烟雾-> 0.3s后拖尾飞行
        --隐藏轮盘内小块
        chipNode.m_baseFirstNode:setVisible(false)


        local waitNode = cc.Node:create()
        self:addChild(waitNode)
            --烟雾
            local yanwu = util_createAnimation("Socre_MagicSpirit_Bonus_yanwu.csb")
            yanwu:setPosition(startPos)
            self:addChild(yanwu, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
            
            yanwu:runCsbAction("actionframe", false, function()
                --拖尾
                self:showCollectTuowei(startPos,endPos )

                --延迟0.3播放下一步 收集栏上涨
                if(not bPlayNext)then
                    bPlayNext = true
                    performWithDelay(waitNode,function() 
                        --更新收集数量后 判断是否全满
                        self:updataCollectNum(false, _func)

                    end,0.3)
                end
                
                yanwu:removeFromParent()
            end)
    end
end

--刷新bonus收集个数
function CodeGameScreenMagicSpiritMachine:updataCollectNum(_isInit, _fun)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local wicks = selfdata.wicks
    if _isInit then
        wicks = wicks or 0
        self.m_respinCollect:setCollectNum(wicks )
    else
        if wicks then
            self.m_respinCollect:updataCollectNum(wicks, _fun)
        end
    end
end



--[[
******************   base下播放classic   *********************
*********************  base下 3个classic触发 
  当成 bonus来触发 需要向服务器发送bonus消息，接到消息才能开始 
--]]

--触发bonus 玩法 开始表现效果
function CodeGameScreenMagicSpiritMachine:showBonusGameView(effectData)

    --开始bonus玩法禁止人物点击
    self:setSpineClickState(false)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self.m_bonusEffectData  = effectData
    self:requestBaseReelClassic( )
end
---
-- 处理spin 返回结果
function CodeGameScreenMagicSpiritMachine:spinResultCallFun(param)

    CodeGameScreenMagicSpiritMachine.super.spinResultCallFun(self,param)

    -- 处理bonus消息返回
    self:featureResultCallFun(param)
end

function CodeGameScreenMagicSpiritMachine:featureResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
       
        if spinData.action == "FEATURE" then
            self.m_iOnceSpinLastWin = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            --发送测试赢钱数
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)
    
            self:setLastWinCoin( spinData.result.winAmount )
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)

            print("featureResultCallFun --------") 
            print(cjson.encode(spinData)) 
            --bugly-21.12.03-之后的逻辑使用回传数据 sets 时，sets数据为nil，加一个日志。
            release_print("featureResultCallFun --------") 
            release_print(cjson.encode(spinData)) 
            
            self.m_featureData:parseFeatureData(spinData.result)
            self.m_spinDataResult = spinData.result

            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

            self:playBaseReelClassicAni( )
        end
    end

    
end

function CodeGameScreenMagicSpiritMachine:requestBaseReelClassic( )
    
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_BONUS_SELECT,jackpot = self.m_jackpotList}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end

--[[
    
*********************  base reel classsic 滚动动画相关
  依次播放classic 
--]]


function CodeGameScreenMagicSpiritMachine:playBaseReelClassicAni( )

    self.m_baseClassicWinCoins = {}

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        -- 触发3个转盘玩法时，背景音乐不停止
        -- self:clearCurMusicBg()
        globalMachineController:playBgmAndResume("MagicSpiritSounds/music_MagicSpirit_bonus_tip.mp3",3,0.4)

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum , 1, -1 do
                local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp  then
                    if self:isFixSymbol(targSp.p_symbolType)  then
                        targSp:runAnim("actionframe")
                    end
                end
            end
        end

        performWithDelay(waitNode,function(  )
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_juese_down.mp3")
            self:playGenieAnim("over",false,17/30,function(  )

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                local leftPositions = selfdata.leftPositions
                local rapidWinCoins = selfdata.rapidWinCoins
                local rapids = selfdata.rapids
                local sets = selfdata.sets

                -- 绿色>粉色>金色
                for k,v in pairs(leftPositions) do
                    local posData = self:getRowAndColByPos(tonumber(k))
                    table.insert(self.m_bonusLeftPos, {
                        pos = tonumber(k),
                        symbolType = tonumber(v),
                        p_cloumnIndex = posData.iY,
                        p_rowIndex = posData.iX,
                    })
                end
                table.sort(
                    self.m_bonusLeftPos,
                    function(a, b)
                        --信号不一致 绿色-粉色-金色
                        if(a.symbolType ~= b.symbolType)then
                            return a.symbolType < b.symbolType
                        --列
                        elseif(a.p_cloumnIndex ~= b.p_cloumnIndex)then
                            return a.p_cloumnIndex < b.p_cloumnIndex
                        --行
                        else
                            return a.p_rowIndex > b.p_rowIndex
                        end
                    end
                )


                --开始bonus玩法禁止人物点击
                self:setSpineClickState(false)
                self:playBaseBonusClassicEffect()
                
            end )
            
            waitNode:removeFromParent()
        end,132/60)
    end,1.5)

end

function CodeGameScreenMagicSpiritMachine:baseReelForeach(fun)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local isJumpFun = fun(node, iCol, iRow)
            if (isJumpFun) then
                return
            end
        end
    end
end

--bonus classic 依次显示
function CodeGameScreenMagicSpiritMachine:playBaseBonusClassicEffect()

    local len = #self.m_bonusLeftPos
    --结束 退出
    if self.m_bonusPlayNum >= len then
            --递归结束回调
            self.m_BaseUpdateAnimCall = function(  )

                -- self:playJueseStartAnimSound()
                self:playGenieAnim("start",false,90/30,function(  )   
                    --结束bonus玩法 恢复
                    self:setSpineClickState(true)
                    self:playGenieIdle( )
                end )

                if self.m_bonusEffectData then
                    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_BONUS)

                    self.m_bonusEffectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                    self.m_bonusEffectData = nil
                end
                self.m_bonusPlayNum = 0
                self.m_bonusLeftPos = {}

            end

            table.sort(
                self.m_bonusLeftPos,
                function(a, b)
                    --列
                    if(a.p_cloumnIndex ~= b.p_cloumnIndex)then
                        return a.p_cloumnIndex < b.p_cloumnIndex
                    --行
                    else
                        return a.p_rowIndex > b.p_rowIndex
                    end
                end
            )
            --
            self.m_BaseUpdateAnimIndex = 1
            self:beginBaseUpdateAnim( )
        return
    end

     --bonus结算延时, 
     local waitNode = cc.Node:create()
     self:addChild(waitNode)
     performWithDelay(waitNode,function()
        --开始弹出轮盘
        self.m_bonusPlayNum = self.m_bonusPlayNum + 1
        self:showBaseClassicSlot(function()

            self:playBaseBonusClassicEffect()

        end)

        waitNode:removeFromParent()
    end, 0.5)
end

--显示Classic轮盘
function CodeGameScreenMagicSpiritMachine:showBaseClassicSlot(_func)
    self:resetMusicBg()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local leftPositions = selfdata.leftPositions
    local rapidWinCoins = selfdata.rapidWinCoins
    local classicWinCoins = selfdata.classicWinCoins
    local rapids = selfdata.rapids
    local sets = selfdata.sets
    
    
    local symbolType = self.SYMBOL_CLASSIC1
    local posReelIndex = 0

    local data = self.m_bonusLeftPos[self.m_bonusPlayNum]
    if data then
        symbolType = data.symbolType
        posReelIndex = tostring(data.pos)  
    end

    -- 获得播放动画的小块《base》
    local fixPos = self:getRowAndColByPos(posReelIndex)
    local iRow = fixPos.iX
    local iCol = fixPos.iY
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

    local spinResult = sets[posReelIndex]
       
    local data = {}
    data.parent = self
    data.symbolType = symbolType
    data.spinTimes = 1
    data.betlevel = self.m_iBetLevel
    data.paytable = classicWinCoins
    data.func = function()
        local winCoins = spinResult.winAmount or 0
        local classicType = symbolType

        if winCoins > 0 then
            local windata = {}
            windata.winCoins = winCoins
            windata.iRow = iRow
            windata.iCol = iCol
            table.insert(self.m_baseClassicWinCoins,windata)
        end

        self:playBaseClassicAniOver(classicType, winCoins,function(  )

            if _func then
                _func()
            end
        end)

        
        
    end
    self.m_classicMachine:restClassicSlots(data )

    
    self:playBaseClassicAniStart(function(  )
        self.m_classicMachine:beginMiniReel()

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            
            spinResult.bet = 0
            spinResult.payLineCount = 0
            self.m_classicMachine:netWorkCallFun(spinResult)

            waitNode:removeFromParent()
        end, 0.5)

    end )
end

function CodeGameScreenMagicSpiritMachine:playBaseClassicAniStart( _func )
    local symbolType = self.SYMBOL_CLASSIC1
    local posReelIndex = 0

    local data = self.m_bonusLeftPos[self.m_bonusPlayNum]
    if data then
        symbolType = data.symbolType
        posReelIndex = data.pos
    end

    -- 获得播放动画的小块《base》
    local fixPos = self:getRowAndColByPos(posReelIndex)
    local iRow = fixPos.iX
    local iCol = fixPos.iY
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    tarSp:setVisible(false)

    local startPos = util_convertToNodeSpace(tarSp,self.m_classicMachine:getParent())
    local endPos = cc.p(0,0)

    self.m_classicMachine:setVisible(true)
    self.m_classicMachine:setPosition(startPos)

    self:showClassicPayTable(nil,symbolType )

    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_enter.mp3")
    -- idle4 闪烁 从棋盘放大后 一直播放到 滚动停止,  移除之前的 idle1 和 idle2 播放时机
    self.m_classicMachine:runCsbAction("start1", false, function()
        self.m_classicMachine:runCsbAction("idle4", true)
    end)
    util_playMoveToAction(self.m_classicMachine,15/30,endPos)
    --显示遮罩
    self:changeBonusMaskShow(true)

    self.m_Anigenie:setVisible(true)
    util_spinePlay(self.m_Anigenie,"actionframe6")
    util_spineEndCallFunc(self.m_Anigenie,"actionframe6", function()
        -- self.m_Anigenie:setVisible(false)
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    --第36帧 小轮盘开始滚动
    performWithDelay(waitNode,function()
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_juese_yaogan.mp3")

        if _func then
            _func()
        end

        waitNode:removeFromParent()
    end, 36/30)

end

function CodeGameScreenMagicSpiritMachine:playBaseClassicAniOver(_classicType, _winCoin, _func)
    local winCoins = _winCoin
    local classicType = _classicType

    --小轮盘停止滚动时 idle4 停止播放，重置为最后一帧
    self.m_classicMachine:pauseForIndex(404)

    local symbolType = self.SYMBOL_CLASSIC1
    local posReelIndex = 0

    local data = self.m_bonusLeftPos[self.m_bonusPlayNum]
    if data then
        symbolType = data.symbolType
        posReelIndex = data.pos
    end

    -- 获得播放动画的小块《base》
    local fixPos = self:getRowAndColByPos(posReelIndex)
    local iRow = fixPos.iX
    local iCol = fixPos.iY
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

    local waitTime = 0
    if winCoins > 0 then
        self.m_classicMachine:updateCoinsLab(winCoins)
        
        self.m_classicMachine:runCsbAction("switch")
        waitTime = 24/60
    end

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        --闪烁赢钱线
        local winIndex = self:getClassicWinIndex(false, classicType)
        self:reworldClassicPayTableAni(false, classicType, winIndex, function()
                self.m_Anigenie:setVisible(false)

                local endPos = util_convertToNodeSpace(tarSp,self.m_classicMachine:getParent())
                --判断赢钱播对应 结束时间线
                gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_over.mp3")
                local overActName = winCoins > 0 and "over2" or "over1"
                self.m_classicMachine:runCsbAction(overActName, false, function()
                    local classicEffect = self:createClassicEffect( tarSp )
                    if classicEffect then
                        classicEffect:setVisible(true)
                        classicEffect:runCsbAction("actionframe", false, function()
                            classicEffect:setVisible(false)
                            --下一步，等待烟雾结束
                            if _func then
                                _func()
                            end
                        end)
                    end
                end)

                local moveTime = 30/60
                util_playMoveToAction(self.m_classicMachine, moveTime, endPos, function(  )
                    tarSp:setVisible(true)
                    self.m_classicMachine:setVisible(false)
    
                    self:overClassicPayTable(false,symbolType,function()
                        -- if _func then
                        --     _func()
                        -- end
                    end)

                    local classicView = self:createClassicWinView( tarSp)
                    if classicView and winCoins > 0 then
                        classicView:pauseForIndex(150)--隐藏赢钱遮罩
                        classicView:updateCoinsLab(winCoins)
                    end
                end)
                --取消遮罩
                self:changeBonusMaskShow(false)
            -- end)
        end)
        
        waitNode:removeFromParent()
    end,waitTime)

end
-- 更改jackpot高亮展示
function CodeGameScreenMagicSpiritMachine:changeBaseJacjpotLight(_isStart, _num)
    if _isStart then
        local jackpotIndex = self.m_JackPotBar:getJackpotIndexBuNum(_num)
        --展示的话 需要修改可见性
        for i=1,6 do
            local jackpot = self.m_JackPotBar:findChild(string.format("Node_jackpot_%d", i))
            if jackpot then
                jackpot:setVisible(i == jackpotIndex)
            end
        end
        self.m_JackPotBar:setIsBonusState(true)
    end
    

    local actionName = _isStart and "start" or "over"
    self.m_JackPotBar:runCsbAction(actionName, false, function()
        if not _isStart then
            self.m_JackPotBar:setIsBonusState(false)
            self.m_JackPotBar:beginLight()
        end
    end)
end

-- function CodeGameScreenMagicSpiritMachine:playBaseBonusFlyOverBottomEffect()
--     --首次使用时再创建，该特效节点只在此接口操作
--     if not self.m_bottomEffect then
--         local label = self.m_bottomUI.m_normalWinLabel
--         local wordPos = label:getParent():convertToWorldSpace(cc.p(label:getPosition()))
--         local pos = self:convertToNodeSpace(wordPos)

--         self.m_bottomEffect = util_createAnimation("MagicSpirit_base_shoujiL.csb")
--         self.m_bottomEffect:setPosition(pos)
--         self:addChild(self.m_bottomEffect, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)
--     end

--     self.m_bottomEffect:setVisible(true)

--     self.m_bottomEffect:runCsbAction("actionframe", false, function()
--         self.m_bottomEffect:setVisible(false)
--     end)
-- end
--[[
************************ respin结束 Classic轮盘依次显示
--]]

--显示Classic轮盘
function CodeGameScreenMagicSpiritMachine:showRespinClassicSlot(_func)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local leftPositions = selfdata.leftPositions
    local rapidWinCoins = selfdata.rapidWinCoins
    local classicWinCoins = selfdata.classicWinCoins
    local rapids = selfdata.rapids
    local sets = selfdata.sets

    local chipNode = self.m_chipList[self.m_playAnimIndex]

    local symbolType = chipNode.p_symbolType or self.SYMBOL_CLASSIC1
    local posReelIndex = tostring( self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex) )  
    local spinResult = sets[posReelIndex]
       

    local data = {}
    data.parent = self
    data.symbolType = symbolType
    data.spinTimes = 1
    data.betlevel = self.m_iBetLevel
    data.paytable = classicWinCoins
    data.func = function()
        local winCoins = spinResult.winAmount or 0
        local selfData = spinResult.selfData or {}
        local rapidWinCoins = selfData.rapidWinCoins or 0
        local isJackpot = rapidWinCoins > 0
        --全满时服务器返回的单个小滚轮赢钱结果已经提前 X2 了，展示时要先 /2(jackpot不乘倍)
        if(self.m_reSpinIsAll and not isJackpot)then
            winCoins = math.floor(winCoins / 2)
        end
        local classicType = symbolType
        self:playRespinClassicAniOver(classicType, winCoins, function()
            local chipNode = self.m_chipList[self.m_playAnimIndex]
            local winView = util_getChildByName(chipNode, "classicWinView")
            if winView then
                winView.m_isJackpot = isJackpot
            end
            if _func then
                _func()
            end
        end)
    end

    self:showClassicPayTable(true, symbolType, function()
        self:playRespinClassicAniStart(function(  )
            self.m_classicMachine:beginMiniReel()
    
    
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode,function(  )
                
                spinResult.bet = 0
                spinResult.payLineCount = 0
                self.m_classicMachine:netWorkCallFun(spinResult)
    
                waitNode:removeFromParent()
            end, 0.5)
    
        end )
    end)
    self.m_classicMachine:restClassicSlots(data )

end

function CodeGameScreenMagicSpiritMachine:playRespinClassicAniStart(_func)
    -- 获得播放动画的小块《Respin》


    local chipNode = self.m_chipList[self.m_playAnimIndex]
    chipNode:setVisible(false)


    local startPos = util_convertToNodeSpace(chipNode,self.m_classicMachine:getParent())
    local endPos = cc.p(0,0)

    self.m_classicMachine:setVisible(true)
    self.m_classicMachine:setPosition(startPos)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        -- idle4 闪烁 从棋盘放大后 一直播放到 滚动停止,  移除之前的 idle1 和 idle2 播放时机
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_enter.mp3")
        self.m_classicMachine:runCsbAction("start1", false, function()
            self.m_classicMachine:runCsbAction("idle4", true)
        end)
        util_playMoveToAction(self.m_classicMachine,15/30,endPos)
        --显示遮罩
        self:changeBonusMaskShow(true)

        self.m_Anigenie:setVisible(true)
        
        util_spinePlay(self.m_Anigenie,"actionframe6")
        
        util_spineEndCallFunc(self.m_Anigenie,"actionframe6", function()
            -- self.m_Anigenie:setVisible(false)
        end)
        --第36帧 小轮盘开始滚动
        performWithDelay(waitNode,function(  )
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_juese_yaogan.mp3")

            if _func then
                _func()
            end

            waitNode:removeFromParent()
        end,36/30)

    end,0)

end

function CodeGameScreenMagicSpiritMachine:playRespinClassicAniOver(_classicType, _winCoin, _func)
    local winCoins = _winCoin
    local classicType = _classicType

    --小轮盘停止滚动时 idle4 停止播放，重置为最后一帧
    self.m_classicMachine:pauseForIndex(404)

    local nextFun = function()
        local chipNode = self.m_chipList[self.m_playAnimIndex]
        --闪烁赢钱线
        local winIndex = self:getClassicWinIndex(true, classicType)
        self:reworldClassicPayTableAni(true, chipNode.p_symbolType, winIndex, function()
                self.m_Anigenie:setVisible(false)
                
                --小轮盘消失
                local endPos = util_convertToNodeSpace(chipNode, self.m_classicMachine:getParent())
                --判断赢钱播对应 结束时间线
                gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_classic_over.mp3")
                local overActName = winCoins > 0 and "over2" or "over1"
                self.m_classicMachine:runCsbAction(overActName, false, function()
                    local classicEffect = self:createClassicEffect( chipNode )
                    if classicEffect then
                        classicEffect:setVisible(true)
                        classicEffect:runCsbAction("actionframe", false, function()
                            classicEffect:setVisible(false)

                            --下一步，等待烟雾结束
                            if _func then
                                _func()
                            end
                        end)
                    end
                end)
                

                local moveTime = 30/60
                util_playMoveToAction(self.m_classicMachine, moveTime, endPos, function()
                    chipNode:setVisible(true)
                    self.m_classicMachine:setVisible(false)

                    self:overClassicPayTable(true, chipNode.p_symbolType,function()
                        -- if _func then
                        --     _func()
                        -- end
                    end)

                    local winView = self:createClassicWinView(chipNode )
                    if winView and winCoins > 0 then
                        winView:pauseForIndex(150)--隐藏赢钱遮罩
                        winView:updateCoinsLab(winCoins)
                    end
                end)
                --取消遮罩
                self:changeBonusMaskShow(false)
        end)
    end
    
    
    

    if winCoins > 0 then
        -- self.m_classicMachine:jumpCoinsLab(winCoins)
        self.m_classicMachine:updateCoinsLab(winCoins)

        self.m_classicMachine:runCsbAction("switch", false, function()
            nextFun()
        end)
    else
        nextFun()
    end
end
-- 更改jackpot高亮展示
function CodeGameScreenMagicSpiritMachine:changeRespinJacjpotLight(_isStart, _num)
    if _isStart then
        local jackpotIndex = self.m_JackPotRsBar:getJackpotIndexBuNum(_num)
        --展示的话 需要修改可见性
        for i=1,6 do
            local jackpot = self.m_JackPotRsBar:findChild(string.format("Node_jackpot_%d", i))
            if jackpot then
                jackpot:setVisible(i == jackpotIndex)
            end
        end
    end
    

    local actionName = _isStart and "start" or "over"
    self.m_JackPotRsBar:runCsbAction(actionName)
end

-- -----
function CodeGameScreenMagicSpiritMachine:showGuoChang(_func ,_delay)
    _delay = _delay or (51/30)
    self.m_guoChang:setVisible(true)
    util_spinePlay(self.m_guoChang,"actionframe")
    util_spineEndCallFunc(self.m_guoChang,"actionframe",function(  )
        self.m_guoChang:setVisible(false)
    end)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        if _func then
            _func()
        end

        waitNode:removeFromParent()
    end, _delay)
end



function CodeGameScreenMagicSpiritMachine:getNextReelSymbolType( )
    
    return self.m_runSpinResultData.p_prevReel
end


function CodeGameScreenMagicSpiritMachine:playCustomSpecialSymbolDownAct( slotNode )

    CodeGameScreenMagicSpiritMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType and self:isFixSymbol(slotNode.p_symbolType)  then

        local slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType,0 )

        slotNode:runAnim("buling",false,function(  )
            if slotNode and slotNode.p_symbolType then
                slotNode:runAnim("idleframe",true)
            end
        end)

    end
end


function CodeGameScreenMagicSpiritMachine:showClassicPayTable(_isRs, _symbolType, _endFun)
    --如果和上次弹板类型一直则不播放入场动画，直接返回 
    local index = _isRs and 2 or 1
    local lastType = self.m_lastPaytableType[index]
    local isPlayAnim = lastType ~= _symbolType
    
    if(not isPlayAnim)then
        
        if(_endFun)then
            _endFun()
        end
        return
    end
    
    self.m_lastPaytableType[index] = _symbolType
    --区分当前应该操作哪个paytable, 保证控件内命名和时间线全部一致
    local paytableView = _isRs and self.m_ResPayTable or self.m_BasePayTable

    paytableView:findChild("Node_lv"):setVisible( _symbolType == self.SYMBOL_CLASSIC1 )
    paytableView:findChild("Node_hong"):setVisible( _symbolType == self.SYMBOL_CLASSIC2 )
    paytableView:findChild("Node_jin"):setVisible( _symbolType == self.SYMBOL_CLASSIC3 )

    gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_paytable_enter.mp3")

    self:upDatePaytableWinCoin(_isRs, _symbolType)
    paytableView:setVisible(true)
    local anctionName = _isRs and "start2" or "start1"
    paytableView:runCsbAction(anctionName, false, function()
        if(_endFun)then
            _endFun()
        end
    end)
end

function CodeGameScreenMagicSpiritMachine:overClassicPayTable(_isRs,_symbolType,_func )
    local paytable = _isRs and self.m_ResPayTable or self.m_BasePayTable
    --小轮盘回归棋盘小块时，暂停action 至 actionframe起始帧
    paytable:pauseForIndex(230)
    --下一个paytable类型相同时 不消失
    local nextSymbolType = self:getNextClassicSymbolType(_isRs)
    local isPlayAnim = _symbolType ~= nextSymbolType
    --reSpin模式最后一个paytable不在 轮盘滚动完毕后淡出
    if(_isRs and 0 == nextSymbolType)then
        isPlayAnim = false
    end

    if(not isPlayAnim)then
        if _func then
            _func()
        end
        return
    end
    
    self:playSmallPaytableOverAction(_isRs, _func)
end
--paytable淡出
function CodeGameScreenMagicSpiritMachine:playSmallPaytableOverAction(_isRs, _func)
    if _isRs then
        self.m_ResPayTable:runCsbAction("over2",false,function(  )
            self.m_ResPayTable:setVisible(false)
            self.m_lastPaytableType[2] = 0
            if _func then
                _func()
            end
        end)
    else
        self.m_BasePayTable:runCsbAction("over2",false,function(  )
            self.m_BasePayTable:setVisible(false)
            self.m_lastPaytableType[1] = 0
            if _func then
                _func()
            end
        end)
    end
end
--下一个小轮盘的信号值, 返回值为0则表示没有下一个小轮盘了
function CodeGameScreenMagicSpiritMachine:getNextClassicSymbolType(_isRs)
    local symbolType = 0

    if(_isRs)then
        local nextIndex = self.m_playAnimIndex + 1
        local chipNode = self.m_chipList[nextIndex]
        if(chipNode)then
            symbolType = chipNode.p_symbolType or self.SYMBOL_CLASSIC1
        end

    else
        local nextIndex = self.m_bonusPlayNum + 1

        local data = self.m_bonusLeftPos[nextIndex]
        if data then
            symbolType = data.symbolType
        end
    end

    return symbolType
end
--获取小轮盘的赢钱索引和节点命名对应
function CodeGameScreenMagicSpiritMachine:getClassicWinIndex(_isRs, _classicType)
    local winIndex = 0
    --小轮盘索引
    local classicIndex = self.m_classicIndexLis[_classicType] or 1
    --小轮盘使用的wind
    local wilds = self.m_classicWildList[classicIndex]

    local reel_data = self.m_classicMachine:getFinalReelData()

    local final_allList = {}
    --最终结果 全部 当前小轮盘的第二三四行
    for _index,_reelData in ipairs(reel_data) do
        if(2 == _index or 3 == _index or 4 == _index)then
            for _iCol,_symbolType in ipairs(_reelData) do
                table.insert(final_allList, _symbolType)
            end
        end
    end
    --最终结果 连线 当前小轮盘的第三行
    local final_list = reel_data[3]
    
    for _winIndex,_data in ipairs(self.m_classicWinIndexList) do
        --区分轮盘类型
        local symbolList = _data.symbolType[classicIndex]
        
        --区分检测类型
        if(1 == _data.check)then
            --使用wild时 必须包含自身检测类型至少一个
            local isHaveSelfType = false

            local count = 0
            
            for i,_symbolType in ipairs(final_list) do
                if(_symbolType == symbolList[1])then
                    count = count + 1
                    isHaveSelfType = true
                elseif(_data.checkWild and wilds[_symbolType])then
                    count = count + 1
                end
            end

            if(isHaveSelfType and count >= _data.checkCount)then
                winIndex = _winIndex
                break
            end
        elseif(2 == _data.check)then
            --使用wild时 必须包含自身检测类型至少一个
            local isHaveSelfType = false

            local bool = true

            for i,_symbolType in ipairs(final_list) do
               
                local isHave = false
                for ii,vv in ipairs(symbolList) do
                    if(_symbolType == vv)then
                        isHave = true
                        isHaveSelfType = true
                        break
                    elseif(_data.checkWild and wilds[_symbolType])then
                        isHave = true
                        break
                    end
                end
                if(not isHave)then
                    bool = false
                    break
                end
            end

            if(isHaveSelfType and bool)then
                winIndex = _winIndex
                break
            end
        elseif(3 == _data.check)then
            --使用wild时 必须包含自身检测类型至少一个
            local isHaveSelfType = false

            local count = 0

            for i,_symbolType in ipairs(final_allList) do
                if(_symbolType == symbolList[1])then
                    count = count + 1
                    isHaveSelfType = true
                elseif(_data.checkWild and wilds[_symbolType])then
                    count = count + 1
                end
            end

            if(isHaveSelfType and count == _data.checkCount)then
                winIndex = _winIndex
                break
            end

        end
    end

    return winIndex
end

function CodeGameScreenMagicSpiritMachine:reworldClassicPayTableAni(_isRs,_symbolType,_winIndex,_func )
    --区分当前应该操作哪个paytable, 保证控件内命名和时间线全部一致
    local paytableView = _isRs and self.m_ResPayTable or self.m_BasePayTable

    paytableView:findChild("Node_lv"):setVisible( _symbolType == self.SYMBOL_CLASSIC1 )
    paytableView:findChild("Node_hong"):setVisible( _symbolType == self.SYMBOL_CLASSIC2 )
    paytableView:findChild("Node_jin"):setVisible( _symbolType == self.SYMBOL_CLASSIC3 )

    for i=1,13 do
        local wil_l_lv = paytableView:findChild("win_l_lv_"..i)
        if wil_l_lv then
            wil_l_lv:setVisible(false)
        end
        local wil_l_hong = paytableView:findChild("win_l_hong_"..i)
        if wil_l_hong then
            wil_l_hong:setVisible(false)
        end
        local wil_l_jin = paytableView:findChild("win_l_jin_"..i)
        if wil_l_jin then
            wil_l_jin:setVisible(false)
        end
    end

    if _symbolType == self.SYMBOL_CLASSIC1 then
        -- 1    2    3    4    5     6      7      8        9         10
        -- 3Jaf 337  327  317  32Br  Any37  31bar  Any3Bar  4scatter  3scatter
        local wil_l_lv = paytableView:findChild("win_l_lv_".._winIndex)
        if wil_l_lv then
            wil_l_lv:setVisible(true)
        end
    elseif _symbolType == self.SYMBOL_CLASSIC2 then
        -- 1    2    3    4    5     6      7      8        9         10
        -- 3Jaf 337  327  317  32Br  Any37  31bar  Any3Bar  4scatter  3scatter
        local wil_l_hong = paytableView:findChild("win_l_hong_".._winIndex)
        if wil_l_hong then
            wil_l_hong:setVisible(true)
        end
    elseif _symbolType == self.SYMBOL_CLASSIC3 then
        -- 1    2    3    4    5     6      7        8         9         10       11      12          13
        -- 337  327  317  32Br Any37 31bar  Any3Bar  4scatter  3scatter  3wildlv  3wildzi 3wildhuang  Any3wild
        local wil_l_jin = paytableView:findChild("win_l_jin_".._winIndex)
        if wil_l_jin then
            wil_l_jin:setVisible(true)
        end
    end

    --改为 持续播放直到小轮盘回归棋盘小块内
    paytableView:runCsbAction("actionframe",false,function()
        paytableView:runCsbAction("actionframe",true)
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenMagicSpiritMachine:showRsFullLockAni( _func )
    self.m_rsFullLock:setVisible(true)
    --X2特效播放的第 0、8、28帧变换数字，同时棋盘上所有小轮盘 播放idle3
    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    self:updateClassicWinViewWinCoin(3)
    performWithDelay(waitNode,function(  )

        self:updateClassicWinViewWinCoin(2)
        self:updateClassicWinViewWinCoin(4)
        performWithDelay(waitNode,function(  )
            self:updateClassicWinViewWinCoin(1)
            self:updateClassicWinViewWinCoin(5)

            --所有idle3播放完毕后(idle3是在同一帧瞬间结束 不考虑延时) 播 actionframe1
            for _index,_chipNode in ipairs(self.m_chipList) do
                local classicWinView = util_getChildByName(_chipNode, "classicWinView")
                if(classicWinView and classicWinView.m_winCoin > 0)then
                    classicWinView:runCsbAction("actionframe1")
                end
            end

            waitNode:removeFromParent()
        end,24/60)
        
    end,8/60)

    self.m_rsFullLock:runCsbAction("actionframe1",false,function(  )

        if _func then
            _func()
        end

        self.m_rsFullLock:setVisible(false)
    end)
end
----reSpin全满时 左上角固定倍率
function CodeGameScreenMagicSpiritMachine:playAllMultipleAnim()
    self.m_reSpinMultiple:setVisible(true)
    self.m_reSpinMultiple:runCsbAction("start", false, function()
        self.m_reSpinMultiple:runCsbAction("idle", true)
    end)

end
--倍率飞往小轮盘
function CodeGameScreenMagicSpiritMachine:playMultipleFly(endFun)
    if(not self.m_reSpinMultiple:isVisible())then
        if(endFun)then
            endFun()
        end
        return
    end
    --创建一个临时的飞往节点,解决层级问题
    local parent = self:findChild("classical")

    local startPos = self.m_reSpinMultiple:getParent():convertToWorldSpace(cc.p(self.m_reSpinMultiple:getPosition()))
    startPos = parent:convertToNodeSpace(startPos)

    local flyNode = util_createAnimation("MagicSpirit_respin_2X.csb")
    flyNode:setPosition(startPos)
    parent:addChild(flyNode, 100)
    self.m_reSpinMultiple:setVisible(false)

    flyNode:runCsbAction("over", false, function()
        self:showRsFullLockAni(function()
            if(endFun)then
                endFun()
            end
        end)
        
        flyNode:removeFromParent()
    end)
end
--倍率
function CodeGameScreenMagicSpiritMachine:updateClassicWinViewWinCoin(_iClo)
    for _index,_chipNode in ipairs(self.m_chipList) do
        if(_iClo == _chipNode.p_cloumnIndex)then
            local classicWinView = util_getChildByName(_chipNode, "classicWinView")
            if(classicWinView)then
                local winCoin = classicWinView.m_winCoin
                if(winCoin > 0)then
                    if not classicWinView.m_isJackpot then
                        winCoin = winCoin * 2
                    end
                    
                    classicWinView:updateCoinsLab(winCoin)
                    classicWinView:runCsbAction("idle3")
                end
            end
        end
    end
end
--reSpin的所有小轮盘滚动结束 收集所有小块分数
function CodeGameScreenMagicSpiritMachine:playReSpinOverCollectAnim(animIndex, endFun)
    --结束后文本还要跳动的时间
    local overJumpTime = 1
    --结束
    if(animIndex > #self.m_winCoinChipList)then
        local waitNode = cc.Node:create()
        self:addChild(waitNode)

        performWithDelay(waitNode,function()
            if(endFun)then
                endFun()
            end

            waitNode:removeFromParent()
        end, overJumpTime+0.5)
        
        return
    end

    local chipNode = self.m_winCoinChipList[animIndex]

    local startPos = util_convertToNodeSpace(chipNode, self)
    local endPos = util_convertToNodeSpace(self.m_reSpinOverView.m_lb_coins, self)

    local interval = 0.4

    local classicWinView = util_getChildByName(chipNode, "classicWinView")
    if(classicWinView and classicWinView.m_winCoin > 0)then
        self:playBonusShoujiAction(chipNode)
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_collectCoin.mp3")
        self:showCollectTuowei(startPos,endPos,function()
            if(0 == self.m_reSpinOverView.m_coins)then
                local time = (#self.m_winCoinChipList-1) * interval + overJumpTime
                self.m_reSpinOverView:jumpCoins(self.m_serverWinCoins, time)
            end
        end)
        --第15帧 播放波纹
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            self.m_reSpinOverView:playFlyOverAnim()
        end, 15/60)
    end

    --下一步
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        self:playReSpinOverCollectAnim(animIndex+1, endFun)

        waitNode:removeFromParent()
    end, interval)
end


--
function CodeGameScreenMagicSpiritMachine:pushAnimNodeToPool(animNode, symbolType)
    self:removeClassicWinViewByAnimNode(animNode )
   CodeGameScreenMagicSpiritMachine.super.pushAnimNodeToPool(self,animNode, symbolType)
   
end
function CodeGameScreenMagicSpiritMachine:getAnimNodeFromPool(symbolType, ccbName)

    local node = CodeGameScreenMagicSpiritMachine.super.getAnimNodeFromPool(self,symbolType, ccbName)
   
    self:removeClassicWinViewByAnimNode(node )

    return node
end


function CodeGameScreenMagicSpiritMachine:updateNetWorkData()

    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    --添加标记
    local features = self.m_runSpinResultData.p_features or {}
    self.m_isPlayWinningNotice = (#features >= 2) and (1 == math.random(1,4))
    --其内含有快滚逻辑
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    
    if self.m_isPlayWinningNotice then
        self:showYuGao(function(  )
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()  -- end
        end)
    else
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  -- end
    end

end

function CodeGameScreenMagicSpiritMachine:showYuGao(_func )
    local func = _func
    self.m_rsDark:setVisible(true)

    --预告中奖音效
    self.m_noticeSoundId = gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_notice.mp3")
    --前置的角色spine
    self.m_spineAheadGenie:setVisible(true)
    util_spinePlay(self.m_spineAheadGenie, "actionframe9")
    util_spineEndCallFunc(self.m_spineAheadGenie,"actionframe9",function()
        self.m_spineAheadGenie:setVisible(false)
    end)

    --actionframe9 0-75帧 用于预告中奖事件帧 Show2 位于第25帧 ，与cocos内棋盘预告中奖时间线同时播放
    self:playGenieAnim("actionframe9", false, 25/30,  function()
        --主界面csd
        self:runCsbAction("actionframe")
        --中奖预告
        self.m_rsDark:runCsbAction("start",false,function(  )
            self.m_rsDark:runCsbAction("idle",false,function(  )
                self.m_rsDark:runCsbAction("over",false,function(  )
                    if func then
                        func()
                    end
                end)
            end)
        end)
    end)

    util_spineEndCallFunc(self.m_genie,"actionframe9", function()
        self:playGenieIdle()
    end)
end

function CodeGameScreenMagicSpiritMachine:beginBaseUpdateAnim( )
    if self.m_BaseUpdateAnimIndex > #self.m_baseClassicWinCoins then
        if self.m_BaseUpdateAnimCall then
            self.m_BaseUpdateAnimCall()
        end
        return
    end

    local isLast = self.m_BaseUpdateAnimIndex == #self.m_baseClassicWinCoins

    local data = self.m_baseClassicWinCoins[self.m_BaseUpdateAnimIndex]
    --当前飞行结束的总赢钱
    local winCoins = 0
    for _index=1,self.m_BaseUpdateAnimIndex do
        winCoins = self.m_baseClassicWinCoins[_index].winCoins + winCoins
    end

    local iCol = data.iCol
    local iRow = data.iRow

    --拖尾
    local tarSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    local startPos = util_convertToNodeSpace(tarSp, self)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self)
    --赢钱 飞往reSpin提示框 -> 飞往底部赢钱框
    self:playBonusShoujiAction(tarSp)
    self:showCollectTuowei(startPos,endPos,function()
        --如果之后存在连线事件则取消飞往结束时的底栏涨钱效果
        
        if isLast then

            -- local winLines = self.m_runSpinResultData.p_winLines or {}
            -- if #winLines <= 0 then
                local beiginCoins = 0
                local endCoins = self.m_serverWinCoins
                local isNotifyUpdateTop = true
                local playWinSound = true
                self:updateBottomUICoins( beiginCoins,endCoins,isNotifyUpdateTop,playWinSound )
            -- end

            --赢钱框动效
            gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_collectCoin.mp3")
            -- self:playBaseBonusFlyOverBottomEffect()
            self:playCoinWinEffectUI()
        end

    end, "actionframe2", 410)

    if isLast then
        self.m_baseBonusUpdateWinCoin = true

        local jumpTime = self.m_bottomUI:getCoinsShowTimes( winCoins )
        local flyTime = 45/60
        
        local delayTime = jumpTime + flyTime
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            self.m_BaseUpdateAnimIndex = self.m_BaseUpdateAnimIndex + 1
            self:beginBaseUpdateAnim( )

            waitNode:removeFromParent()
        end, delayTime)
    else
        --改为一起飞往，不做延时,最后一次飞往需要延时 跳钱时间
        self.m_BaseUpdateAnimIndex = self.m_BaseUpdateAnimIndex + 1
        self:beginBaseUpdateAnim( )
    end
    
    
end

function CodeGameScreenMagicSpiritMachine:showCollectTuowei(_startPos,_endPos ,_func, actionName, length)
    
    local func = _func
    --拖尾
    local fly_tuowei = util_createAnimation("MagicSpirit_respin_tuowei.csb")
    fly_tuowei:setPosition(cc.p(_startPos.x,_startPos.y))
    local order = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM+1      -- GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1
    self:addChild(fly_tuowei, order)
    local rotation = util_getAngleByPos(_startPos,_endPos)
    fly_tuowei:setRotation(- rotation)
    local length = length or 360
    local scaleSize = math.sqrt( math.pow( _startPos.x - _endPos.x ,2) + math.pow( _startPos.y - _endPos.y,2 )) 
    fly_tuowei:setScaleX(scaleSize / length )
    --默认播放1
    actionName = actionName or "actionframe"
    fly_tuowei:runCsbAction(actionName,false,function(  )
        fly_tuowei:stopAllActions()
        fly_tuowei:removeFromParent()
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        if func then
            func()
        end
        waitNode:removeFromParent()
    end,30/60)
   
    return fly_tuowei
end
--Bonus玩法 收集和拖尾一起播放
function CodeGameScreenMagicSpiritMachine:playBonusShoujiAction(bonusNode)
    bonusNode:runAnim("shouji")
    local Node_ClassicWin = bonusNode:getCcbProperty("Node_ClassicWin")
    if Node_ClassicWin then
        local winView = Node_ClassicWin:getChildByName("classicWinView")
        if winView then
            winView:runCsbAction("shouji")
        end
    end
end
--BottomUI接口
function CodeGameScreenMagicSpiritMachine:updateBottomUICoins( _beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound )

    local endCoins = _endCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    local params = {endCoins,isNotifyUpdateTop,nil,_beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
    
end
function CodeGameScreenMagicSpiritMachine:getCurBottomWinCoins()
    local labelStr = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == labelStr then
        return 0
    end

    local numList = util_string_split(labelStr,",")
    local numStr = ""
    for i,v in ipairs(numList) do
        numStr = numStr .. v
    end
    local winCoin = tonumber(numStr)

    return winCoin
end

function CodeGameScreenMagicSpiritMachine:respinOverPlayJpChange( _func )
    local nextFun = function()
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_respin_guochang.mp3")

        --reSpin结束时先播转场(使用低层级的角色) -> 再开始滚动
        --层级大于 jackpot,结束时层级恢复
        local parent = self:findChild("node_genie")
        parent:setLocalZOrder(-7)
        self:playGenieAnim("actionframe", false, 40/30, function()
            --第40帧 触发cocos动效 两种jackpotBar相互切换, 温度计隐藏
            self:changeJackpotBarShow(true, true)

            self.m_respinCollect:runCsbAction("over", false, function()
                self.m_respinCollect:setVisible(false)
                self.m_respinCollect:restCollectView()
                self.m_respinCollect:runCsbAction("idle")
            end)

            if _func then
                _func()
            end
        end)
        --reSpin次数栏
        self:changeReSpinBarShow(false)

       
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function()
            parent:setLocalZOrder(-9)
            

            waitNode:removeFromParent()
        end,90/30)
    end

    globalMachineController:playBgmAndResume("MagicSpiritSounds/music_MagicSpirit_bonus_tip.mp3",3,0.4)
    --所有固定小块播放触发动画
    for _index,_chipNode in ipairs(self.m_chipList) do
        if(1 == _index)then
            _chipNode:runAnim("actionframe", false, function()
                nextFun()
            end)
        else
            _chipNode:runAnim("actionframe")
        end
    end
    
end
--隐藏透明度后 直接吧控件可见性关闭
function CodeGameScreenMagicSpiritMachine:changeReSpinBarShow(isShow)
    if(isShow)then
        self.m_baseReSpinBar:setOpacity(255)
        self.m_baseReSpinBar:setVisible(true)
    else
        local fadeTime = 1
        local act_callfun_bar = cc.CallFunc:create(function()
            util_setCsbVisible(self.m_baseReSpinBar, false)
        end)

        local act_callfun_di = cc.CallFunc:create(function()
            util_setCsbVisible(self.m_reSpinBar_di, false)
            self.m_reSpinBar_di:setOpacity(255)
        end)
        

        self.m_baseReSpinBar:runAction(cc.Sequence:create(cc.FadeOut:create(fadeTime), act_callfun_bar))

        self.m_reSpinBar_di:runAction(cc.Sequence:create(cc.FadeOut:create(fadeTime), act_callfun_di))
    end
end
--判断是否收集满  弹jackpot弹板
function CodeGameScreenMagicSpiritMachine:isCollectTriggerJackpot()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotWinCoins = selfdata.jackpotWinCoins
    if jackpotWinCoins then
        return true
    end
    return false
end
--reSpin 模式 收集精灵头像全满提示
function CodeGameScreenMagicSpiritMachine:showRespinJackpotGrand(_fun)
    local jackPotGrandView = util_createView("CodeMagicSpiritSrc.MagicSpiritRespinJackPotGrandView")
     --解决活动返回时弹板尺寸缩小问题
     if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotGrandView.getRotateBackScaleFlag = function(  ) return false end
    end

    local grandValue = self.m_runSpinResultData.p_selfMakeData.jackpotWinCoins or 0
    local params = {
        winCoins = grandValue,
        fun_close = _fun,
    }
    jackPotGrandView:initViewData(params)
    jackPotGrandView:playStartAnim()

    
    --弹板弹出
    globalMachineController:playBgmAndResume("MagicSpiritSounds/music_MagicSpirit_JackpotView_Diamond.mp3",4,1)
    gLobalViewManager:showUI(jackPotGrandView)
    jackPotGrandView:setPositionY(jackPotGrandView:getPositionY()-150)

    
    --底部赢钱
    local beiginCoins = 0
    local endCoins = grandValue
    local isNotifyUpdateTop = false
    local playWinSound = nil
    self:updateBottomUICoins( beiginCoins,endCoins,isNotifyUpdateTop,playWinSound )
end
-- 版本1 播放人物上升音效，和 start 、 start2 一起播放
-- 版本2 只在回到base时播放
function CodeGameScreenMagicSpiritMachine:playJueseStartAnimSound()
    --第20帧音效
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        gLobalSoundManager:playSound("MagicSpiritSounds/music_MagicSpirit_juese_up.mp3")

        waitNode:removeFromParent()
    end, 24/30)
end
--主界面下潜 -> grand展示 -> 主界面上升 -> 下次reSpin滚动
function CodeGameScreenMagicSpiritMachine:playGrandJueseAnim(_fun)
    --禁止点击
    self:setSpineClickState(false)
    --下潜
    self:playGenieAnim("over", false, 17/30, function()

        --交由grand界面处理, 等待界面关闭
        self:showRespinJackpotGrand(function()
            
            --恢复点击
            self:setSpineClickState(true)
            --上升
            -- self:playJueseStartAnimSound()
            self:playGenieAnim("start2", false, 90/30, function()
                if _fun then
                    _fun()
                end
                --reSpin模式下背景音乐要和人物spine同时循环
                self:playRsGenieIdle()
                self:changeReSpinBgMusic()
            end)

        end)

    end)
end

--点击回调
function CodeGameScreenMagicSpiritMachine:clickFunc(sender)
    local name = sender:getName()

    if name == "spineClick" then
        self:OnSpineClick(sender)
    end
end

function CodeGameScreenMagicSpiritMachine:OnSpineClick(sender)
    if self.m_soundId_juese then
        return
    end
    --reSpin模式不在处理
    local curMode = self:getCurrSpinMode()
    local isRs = curMode == RESPIN_MODE
    if isRs then
        return
    end
    local targetNode = self.m_genie
    if not targetNode:isVisible() then
        return
    end

    --触摸范围
    local rect = targetNode:getBoundingBox()
    local touchPos = sender:getTouchBeganPosition()
    local localPos = targetNode:getParent():convertToNodeSpace(touchPos)
    local isTouchIn = cc.rectContainsPoint(rect, localPos)
    if not isTouchIn then
        return
    end
    --播放音效，同时做动作,可能被打断 所以标记放在延时内处理
    local soundName = string.format("MagicSpiritSounds/music_MagicSpirit_juese_click%d.mp3", math.random(1,2))    
    self.m_soundId_juese = gLobalSoundManager:playSound(soundName)

    self:playGenieAnim("actionframe11",false,75/30,function() 
        self:playGenieIdle()
    end )

    --延时
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()
        self.m_soundId_juese = nil

        waitNode:removeFromParent()
    end, 75/30)
end
function CodeGameScreenMagicSpiritMachine:setSpineClickState(touchEnable)
    self:findChild("spineClick"):setTouchEnabled(touchEnable)
end
function CodeGameScreenMagicSpiritMachine:playSpineClick()
    
end

-- 即将快滚时 人物动效
function CodeGameScreenMagicSpiritMachine:playJueseQuickRunAnim(_reelCol)
    if not self.m_isFirstQuickRun then
        return
    end
    self.m_isFirstQuickRun = false

    local soundName = string.format("MagicSpiritSounds/music_MagicSpirit_juese_Quick_Run%d.mp3", math.random(1,2))
    gLobalSoundManager:playSound(soundName)

    self:playGenieAnim("actionframe12",false,21/30,function(  )   
        self:playGenieAnim("actionframe13",false,70/30,function(  )  
            self:playGenieAnim("actionframe15", true)
        end)
    end )

end

--[[
    paytable乘倍相关 
]]
function CodeGameScreenMagicSpiritMachine:upDatePaytableWinCoin(_isRs, _symbol)
    local paytable = _isRs and self.m_ResPayTable or self.m_BasePayTable
    local tabType =  _isRs and 2 or 1
    local tabIndex = _symbol+1-self.SYMBOL_CLASSIC1
    --信号 ： 格式化名称
    local nodeName = {
        [self.SYMBOL_CLASSIC1] = "m_lb_coins_",
        [self.SYMBOL_CLASSIC2] = "m_lb_coins_",
        [self.SYMBOL_CLASSIC3] = "m_lb_coins_",
    }
    --倍率配置 --默认拿1 就行
    local multiplyCfg = self.PaytableMultiply[1][tabIndex]
    -- local multiplyCfg = self.PaytableMultiply[tabType][tabIndex]

    local nameStr = nodeName[_symbol]

    local awardNode = paytable:findChild(string.format("award_%d", tabIndex))  
    for _nodeIndex,_multiplyValue  in pairs(multiplyCfg) do
        local multiplyLab = awardNode:getChildByName(string.format("%s%d", nameStr, _nodeIndex))
        local winCoin = self:getPaytableWinCoin(tabType, tabIndex,_nodeIndex)
        local coinStr = util_formatCoins(winCoin, 3)

        if multiplyLab  then
            multiplyLab:setString(coinStr)
        end
    end
end
function CodeGameScreenMagicSpiritMachine:getPaytableWinCoin(_tabType, _tabIndex, _winIndex)
    local winCoin = 0

    local curBet = globalData.slotRunData:getCurTotalBet()
    local lines = 75
    local multiply = self:getPaytableMultiply(_tabType, _tabIndex, _winIndex)

    winCoin = curBet * multiply / lines

    return winCoin
end
function CodeGameScreenMagicSpiritMachine:getPaytableMultiply(_tabType, _tabIndex, _winIndex)
    local  value = 0
    -- 两个paytable倍率表一致的话暂时不使用 _tabType
    local multiplyTable = self.PaytableMultiply[1]
    if nil ~= multiplyTable[_tabIndex]  and nil ~= multiplyTable[_tabIndex][_winIndex] then
        value = multiplyTable[_tabIndex][_winIndex]
    end
    
    return value
end
-- =============================================================================一些特殊要求重写父类接口
--解决bonus 3 -> 的快滚
--返回本组下落音效和是否触发长滚效果
function CodeGameScreenMagicSpiritMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum == 2 then
            return runStatus.DUANG, true
        elseif nodeNum == 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 3  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 2 then
            return runStatus.DUANG, true
        elseif nodeNum == 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

function CodeGameScreenMagicSpiritMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    --base模式下bonus玩法提前展示连线并通知赢钱后，屏蔽连线刷新底部赢钱
    if self.m_baseBonusUpdateWinCoin then
        self.m_baseBonusUpdateWinCoin = false
        return
    end

     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

-- 解决reSpin模式bonus玩法结束时 大赢赢钱数值不对问题
---判断结算 原接口 reSpinReel
function CodeGameScreenMagicSpiritMachine:reSpinReelDownMagicSpirit(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    
    self:setGameSpinStage(STOP_RUN)

    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin
    self:updateQuestUI()
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)

        --quest
        self:updateQuestBonusRespinEffectData()

           --结束
        self:reSpinEndAction()

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        --!!!reSpin结束时大赢检测取值修改
        local winCoins = self.m_runSpinResultData.p_resWinCoins or self.m_serverWinCoins
        self:checkFeatureOverTriggerBigWin(winCoins , GameEffect.EFFECT_RESPIN_OVER)
        self.m_isWaitingNetworkData = false

        return
    end

    
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
    end
    --    --下轮数据
    --    self:operaSpinResult()
    --    self:getRandomList()
    --继续
    self:runNextReSpinReel()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

-- 解决reSpin 大赢结束时 播放人物上升
function CodeGameScreenMagicSpiritMachine:showEffect_NewWin(effectData,winType)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    local bigMegaWin = util_createView("views.bigMegaWin.BigWinBg",winType)
    bigMegaWin:initViewData(self.m_llBigOrMegaNum,winType,
        function()

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PLAY_OVER_BIGWIN_EFFECT,{winType = winType})

            -- cxc 2023年11月30日15:02:44  spinWin 需要监测弹（评分，绑定fb, 打开推送）
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("SpinWin", "SpinWin_" .. winType)
            if view then
                view:setOverFunc(function()
                    if not tolua.isnull(self) then
                        if self.playGameEffect then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end)
            else
                --!!!插入代码
                if self.m_reSpinOverPlayAnim then
                    self.m_reSpinOverPlayAnim = false
                    --上升
                    self:playJueseStartAnimSound()
                    self:playGenieAnim("start",false,90/30,function(  )   
                        self:playGenieIdle( )
                        --结束bonus玩法 恢复
                        self:setSpineClickState(true)
                    end)
                    
                end
                

                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end)
    gLobalViewManager:showUI(bigMegaWin)

end

--- 解决播放连线时 挂载的乘倍节点 也播放动画
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenMagicSpiritMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then

            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then

            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end

        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
               self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe",true)
        else
            node:runAnim("actionframe",true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    --!!!修改此处
                    self:runLineAnim(slotsNode)
                end
            end
        end
    end
end
---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMagicSpiritMachine:playInLineNodes()

    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            self:runLineAnim(slotsNode)
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()) )
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end
--小块播放连线动画 所有关卡的切换连线默认都是两个周期 2s
function CodeGameScreenMagicSpiritMachine:runLineAnim(symbolNode)
    symbolNode:runLineAnim()

    --X2播放 时间线
    local mulLab = symbolNode:getChildByName("mulLab")
    if mulLab then
        mulLab:runCsbAction("actionframe")
    end
end

-- 解决bonus快滚检测问题
--设置bonus scatter 信息
function CodeGameScreenMagicSpiritMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    --!!!修改此处
    local symbolCheckList = {}
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
        symbolCheckList[symbolType] = 1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        symbolCheckList = CodeGameScreenMagicSpiritMachine.m_classicIndexLis
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        --!!!修改此处
        if nil ~= symbolCheckList[self:getSymbolTypeForNetData(column,row,runLen)] then
        -- if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end
    --!!!修改此处 预告中奖 和 快滚不同时播放
    if not self.m_isPlayWinningNotice and
        bRun == true and 
        nextReelLong == true and 
        bRunLong == false and 
        self:checkIsInLongRun(column + 1, symbolType) == true then

        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)

    end
    return  allSpecicalSymbolNum, bRunLong
end


--- 解决触发小玩法时 背景音乐被暂停问题
-- 显示bonus 触发的小游戏
function CodeGameScreenMagicSpiritMachine:showEffect_Bonus(effectData)

    self.m_beInSpecialGameTrigger = true

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停止播放背景音乐 --!!!修改此处
    -- self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

        self:showBonusAndScatterLineTip(bonusLineValue,function()
            self:showBonusGameView(effectData)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else

        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end
-- 解决开始滚动时 赢钱展示被移除问题
-- beginReel 时尝试修改层级
function CodeGameScreenMagicSpiritMachine:checkChangeBaseParent()
    --!!!设置快滚标记
    self.m_isFirstQuickRun = true
    --!!!设置赢钱标记
    self.m_baseBonusUpdateWinCoin = false

    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if childs[i].resetReelStatus ~= nil then
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self:resetReelStatus(childs[i])
        end
        if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local posWorld =
                self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(), childs[i]:getPositionY()))
            local pos =
                self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            if not childs[i].p_showOrder then
                childs[i].p_showOrder = self:getBounsScatterDataZorder(childs[i].p_symbolType)
            end
            --裁切层小块放回滚轴要调用这个否则可能下一次spin可能会抖动
            self:changeBaseParent(childs[i])
            childs[i]:setPosition(pos)
            --!!!修改此处
            -- childs[i]:resetReelStatus()
            self:resetReelStatus(childs[i])
        end
    end
end
-- 解决开始滚动时 赢钱展示被移除问题
-- 节点类的接口重写下
function CodeGameScreenMagicSpiritMachine:resetReelStatus(symbolNode)
    if symbolNode.p_symbolImage ~= nil and symbolNode.m_imageName ~= nil then
        symbolNode.p_symbolImage:setVisible(true)
        symbolNode:hideBigSymbolClip()
        --!!!修改此处新增判断
        local Node_ClassicWin = symbolNode:getCcbProperty("Node_ClassicWin")
        --存在 赢钱csb 的话 直接返回，从池子拿出小块创建挂载 赢钱csb 时判断是否存在
        if Node_ClassicWin and Node_ClassicWin:getChildByName("classicWinView") then
            return
        end

        symbolNode:removeAndPushCcbToPool()
    end
    
end

--开始滚动
function CodeGameScreenMagicSpiritMachine:startReSpinRun()
    --日志输出
    local funName = "[CodeGameScreenMagicSpiritMachine:startReSpinRun]"
    self:magicSpiritReleasePrint(funName)

    CodeGameScreenMagicSpiritMachine.super.startReSpinRun(self)
end
--后台日志 和 服务器对了一下, 发现存在 reSpin刚结束 就能点击spin按钮 导致玩法数据被覆盖的bugly报错 21.08.24
-- 在 baseSpin按钮 和 reSpinStart 内加个log,报错时去日志看一下数据
--日志输出:reSpin结束bonus玩法拿不到玩法数据的问题
function CodeGameScreenMagicSpiritMachine:magicSpiritReleasePrint(_funName)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local sets = selfdata.sets or {}
    local msg = string.format("%s m_playAnimIndex=(%d) sets=(%d)", _funName, self.m_playAnimIndex, table_length(sets))
    release_print(msg)
end

return CodeGameScreenMagicSpiritMachine






