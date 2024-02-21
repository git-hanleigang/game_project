--[[
    配置
]]
_G.PlinkoConfig = {}

PlinkoConfig.themeName = "ItemGame_Plinko"

PlinkoConfig.luaPath = "ItemGame.PlinkoCode."
PlinkoConfig.csbPath = "Activity/BeerPlinko/csd/"
PlinkoConfig.otherPath = "Activity/BeerPlinko/other/"

-- 游戏状态:INIT, PLAYING,FINISH（服务器定义）
PlinkoConfig.GameStatus = {
    Init = "INIT",
    Playing = "PLAYING",
    Finish = "FINISH"
}

-- 游戏类型 免费， 付费
PlinkoConfig.UIStatus = {
    Free = 1,
    Pay = 2
}

PlinkoConfig.TRIGGER_SPEED = {
    Normal = 100, -- 普通移动速度
    AutoShoot = 150 -- 中间球触发后的移动速度
}

-- 调试模式
PlinkoConfig.DEBUG_MODE = false

-- 测试模式，不依赖服务器数据和接口
PlinkoConfig.TEST_MODE = false
-- 测试模式下，界面状态
PlinkoConfig.TEST_UIStatus = PlinkoConfig.UIStatus.Free

-- 普通钉子从上到下排列
PlinkoConfig.NormalDingRow = {
    {1, 2},
    {3, 4},
    {5, 6},
    {7, 8},
    {9},
    {14, 15},
    {12, 13},
    {10, 11},
    {18, 19},
    {24, 25},
    {16, 17},
    {20, 21},
    {22, 23, 26, 27},
    {28, 29, 30, 31, 32, 33, 34, 35}
}

-- 杯子个数
PlinkoConfig.CupCount = 11

-- 球尺寸
PlinkoConfig.BallSize = cc.size(44, 44)

-- 触发器，移动数量
PlinkoConfig.MoveCount = 16
-- 触发器，两边位置
PlinkoConfig.MoveLeftPosX = -1 * PlinkoConfig.BallSize.width * 0.5 * (PlinkoConfig.MoveCount - 1) -- -462
PlinkoConfig.MoveRightPosX = PlinkoConfig.BallSize.width * 0.5 * (PlinkoConfig.MoveCount - 1) -- 462

-- 触发器，发射点数量
PlinkoConfig.TriggerCount = 16
-- 触发器，发射位置
PlinkoConfig._getTriggerPosList = function()
    local pos = {}
    local startX = -1 * PlinkoConfig.BallSize.width * 0.5 * (PlinkoConfig.TriggerCount - 1)
    for i = 1, PlinkoConfig.TriggerCount do
        local posX = startX + PlinkoConfig.BallSize.width * (i - 1)
        table.insert(pos, posX)
    end
    return pos
end
PlinkoConfig.TriggerPosList = PlinkoConfig._getTriggerPosList()
print("--- PlinkoConfig.TriggerPosList ---", table.concat(PlinkoConfig.TriggerPosList, "|"))

PlinkoConfig.getNearestPosIndex = function(_posX)
    local minDis = 99999999
    local nearestIndex = nil
    local posList = PlinkoConfig.TriggerPosList
    if posList and #posList > 0 then
        for i = 1, #posList do
            local dis = math.abs(posList[i] - _posX)
            if dis < minDis then
                minDis = dis
                nearestIndex = i
            end
        end
    end
    if nearestIndex then
        return nearestIndex, PlinkoConfig.TriggerPosList[nearestIndex]
    end
    return nil, nil
end

-- 获取球应该停止的位置
-- _posX ，当前位置
PlinkoConfig.getNextPausePosX = function(_posX, _moveDir)
    local posList = PlinkoConfig.TriggerPosList
    if posList and #posList > 0 then
        local len = #posList
        local prePos = nil
        for i = 1, len do
            local triggerPos = posList[i]
            if i == 1 then
                if math.floor(_posX) < math.floor(triggerPos) then
                    return posList[i], -1 * _moveDir, i
                elseif math.floor(_posX) == math.floor(triggerPos) then
                    return posList[i + 1], _moveDir, i + 1
                end
            elseif i > 1 and i < len then
                if math.floor(_posX) <= math.floor(triggerPos) and math.floor(_posX) > math.floor(prePos) then
                    if _moveDir > 0 then
                        return posList[i], _moveDir, i
                    else
                        return posList[i - 1], _moveDir, i - 1
                    end
                end
            elseif i == len then
                if math.floor(_posX) > math.floor(triggerPos) then
                    return posList[i], -1 * _moveDir, i
                elseif math.floor(_posX) == math.floor(triggerPos) then
                    return posList[i - 1], _moveDir, i - 1
                end
            end
            prePos = triggerPos
        end
    end
    assert("!!! getNextPausePosX == nil, _posX = " .. _posX .. ",_moveDir = " .. _posX)
    return nil
end

-- 网络协议
NetType.Plinko = "Plinko"
NetLuaModule.Plinko = "GameModule.Plinko.net.PlinkoNet"

-- 通知
ViewEventType.NOTIFI_PLINKO_COLLISION_CUP = "NOTIFI_PLINKO_COLLISION_CUP" -- 杯子碰撞
ViewEventType.NOTIFI_PLINKO_COLLISION_CUP_LIGHT = "NOTIFI_PLINKO_COLLISION_CUP_LIGHT" -- 杯子碰撞后，其他杯子变暗后再变亮
ViewEventType.NOTIFI_PLINKO_COLLISION_SPECIAL_DING = "NOTIFI_PLINKO_COLLISION_SPECIAL_DING" -- 特殊钉子碰撞
ViewEventType.NOTIFI_PLINKO_CENTER_DING_CRASH = "NOTIFI_PLINKO_CENTER_DING_CRASH" -- 中间钉子解锁
ViewEventType.NOTIFI_PLINKO_MAIN_REWARD_COINS = "NOTIFI_PLINKO_MAIN_REWARD_COINS" -- 总赢钱
ViewEventType.NOTIFI_PLINKO_SPEICAL_DING_CRASH = "NOTIFI_PLINKO_SPEICAL_DING_CRASH" -- 特殊钉子破碎
ViewEventType.NOTIFI_PLINKO_COLLECT_GAME = "NOTIFI_PLINKO_COLLECT_GAME" -- 领奖
ViewEventType.NOTIFI_PLINKO_SPECIAL_DING_BUBBLE = "NOTIFI_PLINKO_SPECIAL_DING_BUBBLE" -- 气泡

-- 游戏钉子 类型
PlinkoConfig.DING_TYPE = {
    NORMAL = 1, -- 普通
    REWARD_DOUBLE = 2, -- 奖励x2
    REWARD_TEN = 3, --奖励x10
    DROP_BALL = 4 --掉落额外的球
}

-- 物理信息
PlinkoConfig.PHYSICS_INFO = {
    WORLD = {
        DEBUG = false,
        DROP_COUNT = 1,
        DROP_IDX = 4,
        AUTO_DROP = 0, -- 小球自动掉落
        AUTO_DROP_INTERVAL = 3, -- 每隔3秒掉落一个
        GRAVITY = cc.p(0, -490) -- 重力
    },
    BALL = {
        RESTITUTION = 1, -- 弹性系数
        MASS = 10, --质量
        INIT_VELOCITY = cc.p(0, -450), -- 开时初始速度
        ANG_VELOCITY = 10, --开始角速度
        MAX_VELOCITY = 700, --球最大速度
        APPLYINPULSE = cc.p(0, 10000) -- 两个球卡住时施加的向上的力 20倍重力
    },
    WALL = {
        RESTITUTION = 2.5 -- 弹性系数
    },
    DING_NORMAL = {
        RESTITUTION = 0.8, -- 弹性系数
        VELOCITY_BALL_FACTOR = 1.4 --推小球一把
    },
    DING_SPECIAL = {
        RESTITUTION = 1.2, -- 弹性系数
        VELOCITY_BALL_FACTOR = 700 -- 推小球一把
    },
    BEER_CUP = {
        RESTITUTION = 0.1 -- 弹性系数
    }
}
