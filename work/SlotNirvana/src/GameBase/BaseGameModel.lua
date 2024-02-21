--[[
    数据基类
    author: 徐袁
    time: 2021-11-27 16:59:47
]]
local BaseGameModel = class("BaseGameModel")
-- FIX IOS xxx
function BaseGameModel:ctor()
    -- 主题资源名
    self.p_themeRes = nil
    -- 引用名
    self.p_reference = nil
    -- 开启等级
    self.p_openLevel = 0
    -- 已完成
    self.p_isCompleted = false
end

-- 解析数据
function BaseGameModel:parseData(data)
end

-- 获得引用名
function BaseGameModel:getRefName()
    return self.p_reference
end

function BaseGameModel:setRefName(ref)
    self.p_reference = ref
end

function BaseGameModel:getModelName()
    return self:getRefName()
end

function BaseGameModel:getThemeName()
    local _theme = self.p_themeRes or ""
    return (_theme == "") and self:getRefName() or _theme
end
-- 设置主题资源名
function BaseGameModel:setThemeName(themeName)
    self.p_themeRes = themeName
end

function BaseGameModel:getOpenLevel()
    return self.p_openLevel or 0
end

function BaseGameModel:onRegister()
end

function BaseGameModel:onRemove()
end

function BaseGameModel:isRunning()
    return true
end

-- 检查开启等级
function BaseGameModel:checkOpenLevel()
    return true
end

-- 是否忽略等级
function BaseGameModel:isIgnoreLevel()
    return false
end

-- 初始化完成状态
function BaseGameModel:initCompleteStatus()
    if self:checkCompleteCondition() then
        self.p_isCompleted = true
    end
end

-- 检查是否达成完成条件，子类覆盖重写
function BaseGameModel:checkCompleteCondition()
    return false
end

-- 是否已完成
function BaseGameModel:isCompleted()
    return self.p_isCompleted
end

-- 设置已经完成状态
function BaseGameModel:setCompleted(status)
    self.p_isCompleted = status
end

-- 是否显示关卡入口
function BaseGameModel:isCanShowEntry()
    return true
end

-- 是否显示关卡BET上的气泡
function BaseGameModel:isCanShowBetBubble()
    return true
end


--获取入口位置 1：左边，0：右边
-- function BaseGameModel:getPositionBar()
--     -- 默认右边，修改重写该方法
--     return 0
-- end

-- 活动入口名称
-- function BaseGameModel:getEntranceName()
--     -- 默认是主题名，上层可以重写覆盖该方法指定其他名称 - -
--     return self:getThemeName()
-- end

return BaseGameModel
