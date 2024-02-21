local BaseActAndSale = class("BaseActAndSale")
-- FIX IOS xxx
function BaseActAndSale:ctor()
    self.p_id = nil
    self.p_activityId = nil
    -- 主题资源名
    self.p_themeRes = nil
    -- 引用名
    self.p_reference = nil
    -- 开启等级
    self.p_openLevel = 0
    -- 剩余时间
    self.p_expire = 0
    -- 到期时间
    self.p_expireAt = 0
    -- 已完成
    self.p_isCompleted = false
    -- 是否忽略过期
    self.p_isIgnoreExpire = false
    -- 新手期活动
    self.p_isNovice = false
end

-- 加载数据
-- function BaseActAndSale:loadData(data)
--     self:parseData(data)
--     -- 解析后初始化一些参数
--     self:initData()
-- end

-- 解析数据
function BaseActAndSale:parseData(data)
end

-- 初始化数据
function BaseActAndSale:initData()
    self:initCompleteStatus()
end

function BaseActAndSale:getID()
    return self.p_id or ""
end

function BaseActAndSale:getActivityID()
    return self.p_activityId or ""
end

function BaseActAndSale:getType()
    return nil
end

-- 获得引用名
function BaseActAndSale:getRefName()
    if self.p_reference and self.p_reference ~= "" then
        return self.p_reference
    else
        -- 没有用主题资源名代替，兼容老表
        return self.p_themeRes or ""
    end
end

function BaseActAndSale:setRefName(ref)
    -- if not self.p_themeRes or self.p_themeRes == "" then
    --     self.p_themeRes = ref
    -- end
    self.p_reference = ref
end

function BaseActAndSale:getModelName()
    return self:getRefName()
end

function BaseActAndSale:getThemeName()
    return self.p_themeRes or ""
end
-- 设置主题资源名
function BaseActAndSale:setThemeName(themeName)
    self.p_themeRes = themeName
end

function BaseActAndSale:onRegister()
end

function BaseActAndSale:onRemove()
end

function BaseActAndSale:getExpire()
    return self.p_expire or 0
end

function BaseActAndSale:getOpenLevel()
    return self.p_openLevel or 0
end

function BaseActAndSale:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function BaseActAndSale:setExpireAt(mSec)
    self.p_expireAt = mSec or 0
end

function BaseActAndSale:isRunning()
    return true
end

function BaseActAndSale:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

-- 检查开启等级
function BaseActAndSale:checkOpenLevel()
    return true
end

-- 是否忽略等级
function BaseActAndSale:isIgnoreLevel()
    return false
end

--获取入口位置 1：左边，0：右边
function BaseActAndSale:getPositionBar()
    -- 默认右边，修改重写该方法
    return 0
end

-- 初始化完成状态
function BaseActAndSale:initCompleteStatus()
    if self:checkCompleteCondition() then
        self.p_isCompleted = true
    end
end

-- 检查是否达成完成条件，子类覆盖重写
function BaseActAndSale:checkCompleteCondition()
    return false
end

-- 是否已完成
function BaseActAndSale:isCompleted()
    return self.p_isCompleted
end

-- 设置已经完成状态
function BaseActAndSale:setCompleted(status)
    self.p_isCompleted = status
end

-- 设置忽略过期
function BaseActAndSale:setIgnoreExpire(flag)
    self.p_isIgnoreExpire = flag
end

-- 是否忽略过期
function BaseActAndSale:isIgnoreExpire()
    return self.p_isIgnoreExpire
end

-- 是否可删除活动
function BaseActAndSale:isCanDelete()
    -- if self:isIgnoreExpire() then
    --     return false
    -- end

    -- if self:getLeftTime() > 0 then
    --     return false
    -- end
    return true
end

-- 活动入口名称
function BaseActAndSale:getEntranceName()
    -- 默认是主题名，上层可以重写覆盖该方法指定其他名称 - -
    return self:getThemeName()
end

-- 大厅展示图模块
function BaseActAndSale:getHallModule()
    local _filePath = "Icons/" .. self:getThemeName() .. "HallNode"
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return "views.lobby.HallNode"
end

-- 轮播图模块
function BaseActAndSale:getSlideModule()
    local _filePath = "Icons/" .. self:getThemeName() .. "SlideNode"
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return "views.lobby.SlideNode"
end

-- 睡眠中
function BaseActAndSale:isSleeping()
    if not self:isIgnoreExpire() and self:getLeftTime() <= 2 then
        return true
    end

    return false
end

-- 是否可显示弹板
function BaseActAndSale:isCanShowPopView()
    if self:isSleeping() then
        return false
    end
    return true
end

-- 弹板模块
function BaseActAndSale:getPopModule()
    local _filePath = "Activity/" .. self:getThemeName()
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        local _module, count = string.gsub(_filePath, "/", ".")
        return _module
    end
    return ""
end

-- 关卡入口模块
function BaseActAndSale:getEntryModule()
    if self:isCanShowEntry() then
        local _filePath = "Activity/" .. self:getRefName() .. "EntryNode"
        if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
            local _module, count = string.gsub(_filePath, "/", ".")
            return _module
        end
    end
    return ""
end

-- 是否显示关卡入口
function BaseActAndSale:isCanShowEntry()
    return true
end

-- 是否显示关卡BET上的气泡
function BaseActAndSale:isCanShowBetBubble()
    return true
end

-- 是否是新手期活动
function BaseActAndSale:isNovice()
    return self.p_isNovice
end

function BaseActAndSale:setNovice(isNovice)
    self.p_isNovice = isNovice or false
end

return BaseActAndSale
