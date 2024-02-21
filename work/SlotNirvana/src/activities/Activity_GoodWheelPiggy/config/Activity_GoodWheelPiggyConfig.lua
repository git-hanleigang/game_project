--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:37:06
]]
local Activity_GoodWheelPiggyConfig = {}

Activity_GoodWheelPiggyConfig.SOUNDS_ENUM = {}

-- 横版资源
Activity_GoodWheelPiggyConfig.MainLayer = "Activity/Activity_GoodWheelPiggy/GoodWheelPiggy_MainLayer.csb"

-- 弹板资源
Activity_GoodWheelPiggyConfig.SendLayer = "Activity/Activity_GoodWheelPiggy/GoodWheelPiggy_SendLayer.csb"

-- 扇叶节点
Activity_GoodWheelPiggyConfig.Slide = "Activity/Activity_GoodWheelPiggy/GoodWheelPiggy_Slide.csb"

-- 轮盘节点
Activity_GoodWheelPiggyConfig.Wheel = "Activity/Activity_GoodWheelPiggy/GoodWheelPiggy_Wheel.csb"

-- 对勾节点
Activity_GoodWheelPiggyConfig.Mark = "Activity/Activity_GoodWheelPiggy/GoodWheelPiggy_duigou.csb"

--spine动画(标题)
Activity_GoodWheelPiggyConfig.SpineTitle = "Activity/Activity_GoodWheelPiggy/spine/GoodWheelPiggy_biaoti"

--spine动画(小猪)
Activity_GoodWheelPiggyConfig.SpinePig = "Activity/Activity_GoodWheelPiggy/spine/GoodWheelPiggy_zhu2"

--sound(转动)
Activity_GoodWheelPiggyConfig.SoundWheelRun = "Activity/Activity_GoodWheelPiggy/sound/sound_wheelRun.mp3"

--sound(选中)
Activity_GoodWheelPiggyConfig.SoundWheelSelect = "Activity/Activity_GoodWheelPiggy/sound/sound_wheelSelect.mp3"

return Activity_GoodWheelPiggyConfig