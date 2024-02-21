local DeluxeCatConfig = {}

-- 功能模块内的事件
DeluxeCatConfig.EVENT_NAME = {
    GAIN_FREE_FOOD_SUCCESS = "GAIN_FREE_FOOD_SUCCESS", -- 成功领取免费猫粮
    FEED_CAT_SUCCESS = "FEED_CAT_SUCCESS", -- 喂猫成功
    HIDE_OTHER_BUBBLE_TIP = "HIDE_OTHER_BUBBLE_TIP", -- 隐藏其他的bubbleTip
    PLAY_CAT_LV_UP = "PLAY_CAT_LV_UP", -- 播放猫升级动画
    SHOW_REWARD_PANEL = "SHOW_REWARD_PANEL", --显示奖励面板
    SHOW_MAX_STEP_GUIDE = "SHOW_MAX_STEP_GUIDE", -- 显示第三步引导
    RESET_RUNNING_ACT_SIGN = "RESET_RUNNING_ACT_SIGN", -- 恢复玩家播放动画中的标识(让玩家可以点击其他操作)
    FEED_CAT_COIN_COLLECTED = "FEED_CAT_COIN_COLLECTED", -- 点击 收集升级经验奖励
    POP_FINAL_REWARD_PANEL = "POP_FINAL_REWARD_PANEL", -- 显示全部最高级后的最终奖励
    HIDE_PROGRESS_UI = "HIDE_PROGRESS_UI", -- 猫咪满级满经验后隐藏 进度条
    RESET_FREE_FOOD_TOUCH_ENABLED = "RESET_FREE_FOOD_TOUCH_ENABLED" -- 恢复领取额免费猫粮触控
}

-- 猫粮type(给服务器传的)
DeluxeCatConfig.FOOD_TYPE_STR = {"Low", "Middle", "High"}

-- 缓存的引导key
DeluxeCatConfig.CACHE_GUIDE_KEY = "CatGameGuideKey"
DeluxeCatConfig.MAX_STEP = 3 -- 最大3步

-- 音效Enum
DeluxeCatConfig.SOUNDS_ENUM = {
    BGM = "Sounds/Cat_bgm.mp3",
    FEED_CAT = "Sounds/Cat_feedCat.mp3",
    GAIN_FREE_FOOD = "Sounds/Cat_gainFreeFood.mp3",
    GAIN_REWARD = "Sounds/Cat_gainReward.mp3",
    GAIN_FINAL_REWARD = "Sounds/Cat_finalReward.mp3",
    LEVEL_UP = "Sounds/Cat_levelUp.mp3",
    PLAY = "Sounds/Cat_tease.mp3",
    COIN_FLY = "Sounds/Cat_coinFly.mp3"
}

-- 猫的Spine配置
local catNames = {"baimao", "hesemao", "huangmao"}
local spinePathSuffixs = {"younian", "chengnian", "chengnian"}
local spineActIdleNames = {"idle", "idle", "idle2"}
local spineActEatNames = {"chi", "chi", "chi2"}
local spineActPlayNames = {"tiaodou", "tiaodou", "tiaodou2"}

function DeluxeCatConfig:getSpineConfig(_idx, _level)
    _idx = _idx or 1
    _level = _level or 1
    _level = math.min(_level, 3)

    local config = {}
    local catName = catNames[_idx]
    local spinePathSuffix = spinePathSuffixs[_level]
    local spineActIdleName = spineActIdleNames[_level]
    local spineActEatName = spineActEatNames[_level]
    local spineActPlayName = spineActPlayNames[_level]

    config["PATH"] = string.format("Spine/%s_%s", catName, spinePathSuffix)
    config["ACT_IDLE"] = spineActIdleName
    config["ACT_EAT"] = spineActEatName
    config["ACT_PLAY"] = spineActPlayName

    return config
end

-- 猫spine的缩放值
local spineScaleList = {}
spineScaleList[1] = {{1, 0.5}, {0.9, 0.5}, {0.9, 0.5}} -- {[lv1] = {centerScale, otherScale}, [lv2] = {centerScale, otherScale}, [lv3] = {centerScale, otherScale}}
spineScaleList[2] = {{1, 0.7}, {0.82, 0.5}, {0.8, 0.5}}
spineScaleList[3] = {{0.8, 0.5}, {0.65, 0.4}, {0.65, 0.4}}
function DeluxeCatConfig:getCatSpineScale(_idx, _level, _bCenter)
    _idx = _idx or 1
    _level = _level or 1

    local spineScaleInfo = spineScaleList[_idx][_level] or {1, 1}
    local scale = spineScaleInfo[2]
    if _bCenter then
        scale = spineScaleInfo[1]
    end
    return scale
end

-- 获取猫嘴的位置
local mouthPosList = {}
mouthPosList[1] = {cc.p(76, 220), cc.p(118, 337)} -- 白猫
mouthPosList[2] = {cc.p(34, 140), cc.p(7, 380)} -- 褐色猫
mouthPosList[3] = {cc.p(62, 76), cc.p(102, 494)} -- 橘猫
function DeluxeCatConfig:getCatMouthPos(_catIdx, _level)
    local allPos = mouthPosList[_catIdx] or {}
    local idx = math.min(_level, 2)
    return allPos[idx] or cc.p(0, 0)
end

-- 获取猫头的位置(头上播放经验升级动画)
local headExpUpPosList = {}
headExpUpPosList[1] = {cc.p(28, 357), cc.p(108, 400)} -- 白猫
headExpUpPosList[2] = {cc.p(55, 244), cc.p(2, 448)} -- 褐色猫
headExpUpPosList[3] = {cc.p(85, 256), cc.p(100, 570)} -- 橘猫
function DeluxeCatConfig:getCatHeadExpUpPos(_catIdx, _level)
    local allPos = headExpUpPosList[_catIdx] or {}
    local idx = math.min(_level, 2)
    return allPos[idx] or cc.p(0, 0)
end

-- 为当前显示的猫添加一个触摸板 从而可以挑逗它
local touchLayoutUIConfig = {}
touchLayoutUIConfig[1] = {{cc.p(20, 0), cc.size(220, 360)}, {cc.p(40, 0), cc.size(300, 500)}} -- 白猫
touchLayoutUIConfig[2] = {{cc.p(30, 0), cc.size(290, 240)}, {cc.p(20, 0), cc.size(350, 530)}} -- 褐色猫
touchLayoutUIConfig[3] = {{cc.p(50, 0), cc.size(380, 270)}, {cc.p(50, 0), cc.size(450, 700)}} -- 橘猫
function DeluxeCatConfig:getCatTouchConfig(_showIdx, _level)
    local config = touchLayoutUIConfig[_showIdx] or {}
    local idx = math.min(_level, 2)
    return config[idx] or {}
end

return DeluxeCatConfig
