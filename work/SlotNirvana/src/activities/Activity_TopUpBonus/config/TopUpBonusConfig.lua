-- 全服累充活动配置

local TopUpBonusConfig = {}

-- 给一个默认主题 应对现在没填写多主题会报错的问题
TopUpBonusConfig.theme = "Activity_AddPay"

-- 设置主题
function TopUpBonusConfig.setThemeName(theme_str)
    TopUpBonusConfig.theme = theme_str
    TopUpBonusConfig.reloadFile()
end

-- 获取主题
function TopUpBonusConfig.getThemeName()
    return TopUpBonusConfig.theme
end

-- 重新加载
function TopUpBonusConfig.reloadFile()
    local theme_name = TopUpBonusConfig.getThemeName()
    local theme_path = theme_name .. "/Activity/"
    -- 主界面相关资源 --
    TopUpBonusConfig.mainUI = theme_path .. "TopUpBonus_MainLayer.csb"
    TopUpBonusConfig.itemUI = theme_path .. "TopUpBonus_TaskItem.csb"
    TopUpBonusConfig.tipUI = theme_path .. "TopUpBonus_TipLayer.csb"
    TopUpBonusConfig.wheelUI = theme_path .. "TopUpBonus_WheelLayer.csb"
    TopUpBonusConfig.wheelNodeUI = theme_path .. "TopUpBonus_Wheel.csb"
    TopUpBonusConfig.wheelItemNodeUI = theme_path .. "TopUpBonus_WheelItem.csb"
end

--改动比较大的主题单独处理
function TopUpBonusConfig.getThemeFile(theme_str)
    local path = "Activity/"..TopUpBonusConfig.theme 
    return path
end

return TopUpBonusConfig
