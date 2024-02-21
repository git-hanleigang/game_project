--[[
]]
local PokerConfig = class("PokerConfig")

function PokerConfig:ctor()
    self:initCfg()
end

function PokerConfig:getInstance()
    if self.instance == nil then
        self.instance = PokerConfig.new()
    end
    return self.instance
end

function PokerConfig:initCfg()
    -- 需要拼接的路径，方便以后换皮用
    self.luaPath = "Activity.PokerCode."
    self.csbPath = "Activity/Activity_Poker/csd/"
    self.otherPath = "Activity/Activity_Poker/other/"
    self.lobbyPath = "Activity_LobbyIconRes/ui/"

    -- 相对较全的路径
    self.taskEntryCsbPath = "Activity_Mission/csd/COIN_POKER_MissionEntryNode"
    self.taskEntryLuaPath = "views/Activity_Mission/ActivityTaskBottom_poker"
    -- 需要拼接的路径
    self.taskCsbPath = "Activity/Activity_PokerTask/csd/"

    -- { "文字描述", "筹码索引"}
    self.POKER_PAY_TABLE = {
        ["JackOrBetter"] = {"Jacks Or Better", 1},
        ["TwoPair"] = {"Two Pairs", 2},
        ["ThreeOfAKind"] = {"Three Of A Kind", 3},
        ["Straight"] = {"Straight", 4},
        ["Flush"] = {"Flush", 5},
        ["FullHouse"] = {"Full House", 6},
        ["FourOfAKind"] = {"Four Of A Kind", 7},
        ["StraightFlush"] = {"Straight Flush", 8},
        ["FiveOfAKind"] = {"Five Of A Kind", 9},
        ["JokerRoyalFlush"] = {"Joker Royal", 10},
        ["RoyalFlush"] = {"Royal Flush", 11}
    }

    self.POKER_DUBBING = {}
end

function PokerConfig:getPayTableChipNum(_winType)
    if not _winType and self.POKER_PAY_TABLE[_winType] then
        return 0
    end
    local cfg = self.POKER_PAY_TABLE[_winType]
    if not cfg then
        return 0
    end
    return self:getPayTableNum(cfg[2])
end

function PokerConfig:getPayTableNum(_index)
    local list = globalData.constantData.POKER_PAYTABLE
    local num = list and list[_index]
    return num or 0
end

-- 多主题重写此方法
-- 配置关卡能量收集条相关信息(日志 跳转 收集特效)
-- 从 EntryNodeConfig.popup_config 中迁移过来的
function PokerConfig:getEntryNodeDataCfg()
    return {
        entry_type = "TapOpen", -- 活动左边条 打点传入参数
        entry_node_name = "PokerStageIcon", -- 活动左边条 打点传入参数
        lua_file = "PokerMainUI", -- 活动主界面lua名称
        fly_effect_name = "Activity/Activity_Poker/other/ticket_fly.png", -- 飞行动画索引路径
        effect_nums = 12, -- 创建特效数量
        is_rotation = false -- 飞行的时候 是否旋转
    }
end

-- 多主题重写此方法
-- 关卡弹框列表 只有继承了EntryNodeBase的活动类才有效
-- 从 EntryNodeConfig.popup_config 中迁移过来的， 方便多主题控制
function PokerConfig:getEntryNodePopCfg()
    return {
        ["levelUp"] = "Activity/Activity_Poker", -- 升级弹板lua文件路径
        -- 关卡内获得新的活动次数弹板 走统一逻辑 这里配置资源就可以了
        ["collect"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "PokerMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Activity_Poker/csd/Poker_PopCollect/Poker_CollectPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/Activity_Poker/csd/Poker_PopCollect/Poker_CollectPop_Portrait.csb" -- 竖版资源路径
        },
        -- 关卡内累积活动次数达到上限弹板 走统一逻辑 这里配置资源就可以了
        ["collect_max"] = {
            ["lua_file"] = "baseActivity/ActivityExtra/Activity_CollectMaxPop", -- ！！！这里有通用弹板 也支持自由指定 但是初始化参数不支持扩展
            ["game_file"] = "PokerMainUI", -- 跳转活动主界面名称
            ["horizontal"] = "Activity/Activity_Poker/csd/Poker_PopCollect/Poker_CollectMaxPop.csb", -- 横版资源路径
            ["portrait"] = "Activity/Activity_Poker/csd/Poker_PopCollect/Poker_CollectMaxPop_Portrait.csb" -- 竖版资源路径
        }
    }
end

return PokerConfig
