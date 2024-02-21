--
-- 等级数据信息
-- Author:{author}
-- Date: 2019-04-10 17:27:15
--
local LevelData = class("LevelData")

LevelData.p_level = nil  -- 等级
LevelData.p_exp = nil    -- 升级到下一级所需要经验
LevelData.p_coins = nil  -- 升级到下一级奖励金币
LevelData.p_coinsShow = nil --下面银库铜库轮盘奖励原始数据
LevelData.p_bronze = nil    -- 铜库奖励
LevelData.p_treasury = nil  -- 银库奖励
LevelData.p_wheel = nil    -- 转盘奖励
LevelData.p_vipPoint = nil  -- 升级奖励vip 点数
LevelData.p_clubPoint = nil  -- 高倍场 点数

function LevelData:ctor()

end

return  LevelData