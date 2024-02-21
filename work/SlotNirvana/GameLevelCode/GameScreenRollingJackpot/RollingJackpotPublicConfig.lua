local RollingJackpotPublicConfig = {}

local localizationType = { --本地化类型
    TXT                 = 1,    --文本类型
    PNG                 = 2,    --图片类型
    BTNNORMAL           = 3,    --按钮的正常状态
    BTNPRESSED          = 4,    --按钮的按下状态
    BTNDISABLED         = 5,    --按钮的禁用状态
    CSBANI              = 10,   -- .csb的时间线的名称
    POS                 = 11,   --节点的位置配置 有些节点的位置在中英下是不一样的
}

function RollingJackpotPublicConfig:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function RollingJackpotPublicConfig:getInstance()
    if self.instance == nil then
        self.instance = self:new()
        self.instance:initData()
    end
    return self.instance
end

function RollingJackpotPublicConfig:initData( )
    self:initSoundConfig()
    --self:initLocalizationConfig()
    self:initGameData()
end

--音效路径 
function RollingJackpotPublicConfig:initSoundConfig()
    self.SoundConfig = {
        --JMS-雷神777-Bonus图标落地
        sound_RollingJackpot_Bonus_buling = "RollingJackpotSounds/sound_RollingJackpot_Bonus_buling.mp3",

        --JMS-雷神777-JP数字滚动
        sound_jackpotView_num_jump = "RollingJackpotSounds/sound_RollingJackpot_JackpotView_jumpCoins.mp3",

        --JMS-雷神777-JP数字滚动结束音
        sound_jackpotView_num_end = "RollingJackpotSounds/sound_RollingJackpot_JackpotView_jumpCoinsOver.mp3",

        --JMS-雷神777-Scatter图标落地
        sound_RollingJackpot_Scatter_buling = "RollingJackpotSounds/sound_RollingJackpot_Scatter_buling.mp3",

        --JMS-雷神777-BG中奖连线1
        sound_base_winLine_1 = "RollingJackpotSounds/sound_RollingJackpot_baseLineFrame_1.mp3",

        --JMS-雷神777-BG中奖连线2
        sound_base_winLine_2 = "RollingJackpotSounds/sound_RollingJackpot_baseLineFrame_2.mp3",

        --JMS-雷神777-BG中奖连线3
        sound_base_winLine_3 = "RollingJackpotSounds/sound_RollingJackpot_baseLineFrame_3.mp3",

        --JMS-雷神777-点击
        sound_base_dialog = "RollingJackpotSounds/sound_RollingJackpot_commonClick.mp3",

        --JMS-雷神777-进入关卡短乐+WELCOME TO  ROLLING JACKPOT
        sound_RollingJackpot_enterLevel = "RollingJackpotSounds/sound_RollingJackpot_enterLevel.mp3",

        --JMS-雷神777-FG中奖连线1
        sound_free_winLine_1 = "RollingJackpotSounds/sound_RollingJackpot_freeLineFrame_1.mp3",

        --JMS-雷神777-FG中奖连线2
        sound_free_winLine_2 = "RollingJackpotSounds/sound_RollingJackpot_freeLineFrame_2.mp3",

        --JMS-雷神777-FG中奖连线3
        sound_free_winLine_3 = "RollingJackpotSounds/sound_RollingJackpot_freeLineFrame_3.mp3",

        --JMS-雷神777-FG预告中奖+A CLASSIC THOR ADVENTURE!
        sound_RollingJackpot_notice_1 = "RollingJackpotSounds/sound_RollingJackpot_notice_1.mp3",

        --JMS-雷神777-大赢前预告中奖
        sound_RollingJackpot_notice_2 = "RollingJackpotSounds/sound_RollingJackpot_notice_2.mp3",

        --JMS-雷神777-RAPID预告中奖+YOU HAVE THOR'S BLESSING!
        sound_RollingJackpot_notice_3 = "RollingJackpotSounds/sound_RollingJackpot_notice_3.mp3",

        --JMS-雷神777-快滚
        sound_RollingJackpot_reelRun_1 = "RollingJackpotSounds/sound_RollingJackpot_reelRun_1.mp3",

        --JMS-雷神777-Reel Stop（普通）
        sound_RollingJackpot_reelStopCommon = "RollingJackpotSounds/sound_RollingJackpot_reelStopCommon.mp3",

        --JMS-雷神777-Reel Stop（快停）
        sound_RollingJackpot_reelStopQuick = "RollingJackpotSounds/sound_RollingJackpot_reelStopQuick.mp3",

        --JMS-雷神777-Scatter图标触发+THAT'S WHAT HEROES DO!
        sound_RollingJackpot_2 = "RollingJackpotSounds/sound_RollingJackpot_2.mp3",

        --JMS-雷神777-FG回到BG过场动画
        sound_freeToBase_change = "RollingJackpotSounds/sound_RollingJackpot_3.mp3",

        --JMS-雷神777-FG开始弹板弹出
        sound_freeStart_show = "RollingJackpotSounds/sound_RollingJackpot_4.mp3",

        --JMS-雷神777-BET解锁
        sound_bet_unlock = "RollingJackpotSounds/sound_RollingJackpot_5.mp3",

        --JMS-雷神777-棋盘升行动画
        sound_RollingJackpot_7 = "RollingJackpotSounds/sound_RollingJackpot_7.mp3",

        --JMS-雷神777-FG结算弹板收回
        sound_freeOver_over = "RollingJackpotSounds/sound_RollingJackpot_8.mp3",

        --JMS-雷神777-FG升级弹板弹出+收回+UPGRADE!
        sound_RollingJackpot_10 = "RollingJackpotSounds/sound_RollingJackpot_10.mp3",

        --JMS-雷神777-达成的档位JACKPOT框移动
        sound_RollingJackpot_11 = "RollingJackpotSounds/sound_RollingJackpot_11.mp3",

        --JMS-雷神777-Bonus图标收集动画2
        sound_RollingJackpot_15 = "RollingJackpotSounds/sound_RollingJackpot_15.mp3",

        --JMS-雷神777-JP弹板弹出+JACKPOT IS YOURS!
        sound_RollingJackpot_19 = "RollingJackpotSounds/sound_RollingJackpot_19.mp3",

        --JMS-雷神777-JP栏最后中奖动画+HUMAN... YOU'RE SO LUCKY.
        sound_RollingJackpot_20 = "RollingJackpotSounds/sound_RollingJackpot_20.mp3",

        --JMS-雷神777-Bonus图标收集动画1
        sound_RollingJackpot_21 = "RollingJackpotSounds/sound_RollingJackpot_21.mp3",

        --JMS-雷神777-JP升级弹板弹出+收回
        sound_RollingJackpot_22 = "RollingJackpotSounds/sound_RollingJackpot_22.mp3",

        --JMS-雷神777-RAPID图标触发
        sound_RollingJackpot_23 = "RollingJackpotSounds/sound_RollingJackpot_23.mp3",

        --JMS-雷神777-RAPID图标落地
        sound_RollingJackpot_26 = "RollingJackpotSounds/sound_RollingJackpot_26.mp3",

        --JMS-雷神777-FG开始弹板收回
        sound_freeStart_over = "RollingJackpotSounds/sound_RollingJackpot_28.mp3",

        --JMS-雷神777-JP栏移动到目前档位JP框
        sound_RollingJackpot_29 = "RollingJackpotSounds/sound_RollingJackpot_29.mp3",

        --JMS-雷神777-JP弹板收回
        sound_RollingJackpot_32 = "RollingJackpotSounds/sound_RollingJackpot_32.mp3",

        --JMS-雷神777-BG进入FG过场动画
        sound_baseToFree_change = "RollingJackpotSounds/sound_RollingJackpot_36.mp3",

        --JMS-雷神777-FG结算弹板弹出
        sound_freeOver_show = "RollingJackpotSounds/sound_RollingJackpot_38.mp3",

        --JMS-圣诞雪怪-bet上锁
        sound_bet_lock = "RollingJackpotSounds/sound_RollingJackpot_bet_lock.mp3",
    }
end

--本地化的一些配置
function RollingJackpotPublicConfig:initLocalizationConfig()
    self.LocalizationConfig = {
        --[10001]这个就是一个ID 唯一即可  
        -- [10001] = {
               --name 对应的是节点的名称  Type：本地化的类型   En/Cn：不同语言对应的信息 如：图片类型就是对应的资源路径
        --     {name = "nodeName", Type = localizationType.PNG,En="RollingJackpotLocalization/EN/xxxx.png",Cn="RollingJackpotLocalization/CN/xxxx.png"},
        -- }
    }
end

--存一些关卡的数据，避免因为一些需要跨界面处理的数据传来传去
function RollingJackpotPublicConfig:initGameData()
    self.m_GameData = {}
end
--设置数据
function RollingJackpotPublicConfig:setGameData(key, value)
    self.m_GameData[key] = value
end
--获取数据
function RollingJackpotPublicConfig:getGameData(key)
    return self.m_GameData[key]
end

--获取当前档位的jackpot的值
function RollingJackpotPublicConfig:getCurLevelInfo()
    local curIndex = self:getGameData("currentIndex")
    local info = self:getLevelInfoByIndex(curIndex)
    return info
end

function RollingJackpotPublicConfig:getnextLevelInfo()
    local curIndex = self:getGameData("currentIndex")
    local nextIndex  = curIndex + 1
    local info = self:getLevelInfoByIndex(nextIndex)
    return info
end

function RollingJackpotPublicConfig:getLevelInfoByIndex(index)
    local infos = self:getGameData("freeCollect") --freeJackpot的总数据
    local info = infos[index]
    return info
end

--获取当前剩余的个数
function RollingJackpotPublicConfig:getCurResidueCollectNum()
    local info = self:getCurLevelInfo()
    local totalNum = info.bonusTimes
    local curCollectNum = self:getGameData("curCollectCount")
    return math.max(totalNum - curCollectNum, 0) 
end

--获取当前的剩余free次数
function RollingJackpotPublicConfig:getCurResidueFreeNum()
    local leftFreeCount = self:getGameData("leftFreeCount")
    return leftFreeCount
end

return RollingJackpotPublicConfig