---
--island
--2017年9月1日
--GameEffectData.lua
-- 游戏内播放effect 的数据

local GameEffectData = class("GameEffectData")

GameEffectData.p_effectType = nil  --创建属性
GameEffectData.p_isPlay = nil -- 是否播放完毕 
GameEffectData.p_effectData = nil -- 自定义放置的数据  可以不用 
GameEffectData.p_effectOrder = nil --动画播放层级 用于动画播放顺序排序
GameEffectData.p_selfEffectType = nil --自定义动画类型 用于区分关卡中触发多个动画
-- 构造函数
function GameEffectData:ctor()
    self.p_isPlay = false
    self.p_effectType = GameEffect.EFFECT_NONE
    self.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
end


return GameEffectData