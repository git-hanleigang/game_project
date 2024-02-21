-- 全服累充活动配置

local AddPayConfig = {}

-- 给一个默认主题 应对现在没填写多主题会报错的问题
AddPayConfig.theme = "Activity_AddPay"

-- 设置主题
function AddPayConfig.setThemeName(theme_str)
    if theme_str == "Activity_AddPay" then
        AddPayConfig.theme = theme_str
    elseif theme_str == "Activity_AddPayPinnacle" then
        AddPayConfig.theme = theme_str
    end

    AddPayConfig.reloadFile()
end

-- 获取主题
function AddPayConfig.getThemeName()
    return AddPayConfig.theme
end

-- 重新加载
function AddPayConfig.reloadFile()
    local theme_name = AddPayConfig.getThemeName()
    local theme_path = theme_name .. "/Activity/"
    -- 主界面相关资源 --
    AddPayConfig.mainUI = theme_path .. "AddPay_MainLayer.csb"
    AddPayConfig.itemUI = theme_path .. "AddPay_Item.csb"
    AddPayConfig.priceUI = theme_path .. "AddPay_Item_Price.csb"
end

--改动比较大的主题单独处理
function AddPayConfig.getThemeFile(theme_str)
    local path = "Activity/Activity_AddPay"
    if theme_str == "Activity_AddPayPinnacle" then
        path = "Activity/Activity_AddPayPinnacle"
    end
    return path
end

return AddPayConfig
