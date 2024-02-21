local DartsGameConfig = {}

local DartsGameBulletType = {
    ["ball"] = "ball",              --球
    ["stoneaxe"] = "stoneaxe",      --石头斧
    ["knife"] = "knife",            --刀子
    ["banana"] = "banana",          --香蕉
    ["dartsarrow"] = "dartsarrow",  --飞镖
    ["boomerang"] = "boomerang",    --回旋镖
}
DartsGameConfig.DartsGameBulletType = DartsGameBulletType

local DartsGameBulletTypeArray = {
    DartsGameBulletType.dartsarrow,
    DartsGameBulletType.banana,
    DartsGameBulletType.knife,
    DartsGameBulletType.ball,
    DartsGameBulletType.boomerang,
    DartsGameBulletType.stoneaxe,
}
DartsGameConfig.DartsGameBulletTypeArray = DartsGameBulletTypeArray

local DartsGameBulletType2Index = {
    [DartsGameBulletType.ball] = 4,
    [DartsGameBulletType.stoneaxe] = 6,
    [DartsGameBulletType.knife] = 3,
    [DartsGameBulletType.banana] = 2,
    [DartsGameBulletType.dartsarrow] = 1,
    [DartsGameBulletType.boomerang] = 5,
}
DartsGameConfig.DartsGameBulletType2Index = DartsGameBulletType2Index

local DartsGameBulletType2ActName = {
    [DartsGameBulletType.ball] = 'start_ball',
    [DartsGameBulletType.stoneaxe] = 'start_stoneaxe',
    [DartsGameBulletType.knife] = 'start_knife',
    [DartsGameBulletType.banana] = 'start_banana',
    [DartsGameBulletType.dartsarrow] = 'start_dartsarrow',
    [DartsGameBulletType.boomerang] = 'start_boomerang',
}
DartsGameConfig.DartsGameBulletType2ActName = DartsGameBulletType2ActName

local DartsGameBulletTypePayArray = {
    DartsGameBulletType.dartsarrow,
    DartsGameBulletType.stoneaxe,
    DartsGameBulletType.knife,
    DartsGameBulletType.stoneaxe,
    DartsGameBulletType.knife,
    DartsGameBulletType.stoneaxe,
}
DartsGameConfig.DartsGameBulletTypePayArray = DartsGameBulletTypePayArray

local viewEventType = ViewEventType
viewEventType.NOTIFI_DARTS_SPIN_SUCC = "NOTIFI_DARTS_SPIN_SUCC"
viewEventType.NOTIFI_DARTS_SPIN_FAILED = "NOTIFI_DARTS_SPIN_FAILED"

viewEventType.NOTIFI_DARTS_END_SUCC = "NOTIFI_DARTS_END_SUCC"
viewEventType.NOTIFI_DARTS_END_FAILED = "NOTIFI_DARTS_END_FAILED"

viewEventType.NOTIFI_DARTS_PAY_SUCC = "NOTIFI_DARTS_PAY_SUCC"
viewEventType.NOTIFI_DARTS_PAY_FAILED = "NOTIFI_DARTS_PAY_FAILED"

viewEventType.NOTIFI_DARTS_REWARD_SUCC = "NOTIFI_DARTS_REWARD_SUCC"
viewEventType.NOTIFI_DARTS_REWARD_FAILED = "NOTIFI_DARTS_REWARD_FAILED"

viewEventType.NOTIFI_DARTS_PAY_SUCC_2_MAIN = "NOTIFI_DARTS_PAY_SUCC_2_MAIN"
viewEventType.NOTIFI_DARTS_SWITCH_PAYMENT = "NOTIFI_DARTS_SWITCH_PAYMENT" --切换付费界面


viewEventType.NOTIFI_DARTS_CLOSE_REWARD = "NOTIFI_DARTS_CLOSE_REWARD"


viewEventType.NOTIFI_DARTS_PAY_REWARD_CLOSE = "NOTIFI_DARTS_PAY_REWARD_CLOSE"   --付费奖励界面关闭

return DartsGameConfig