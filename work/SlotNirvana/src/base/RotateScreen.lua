--[[
    旋转屏幕管理
    author:徐袁
    time:2021-03-13 17:49:20
]]
local _RotateScreen = class("RotateScreen")

local rotateInfo = {
    -- ID
    rotateId = 0,
    -- 旋转方向:Portrait 或 Landscape
    rotateDir = "Landscape",
    -- 引用计数
    rotateRef = 0
}

-- 获得旋转方向
local getRotateDir = function(isPortrait)
    if isPortrait then
        return "Portrait"
    else
        return "Landscape"
    end
end

local isPortraitDir = function(dir)
    if dir == "Portrait" then
        return true
    else
        return false
    end
end

function _RotateScreen:ctor()
    self.m_initPortraitDir = false

    self:clearRotateData()
end

function _RotateScreen:getInstance()
    if self._instance == nil then
        self._instance = _RotateScreen.new()
    end
    return self._instance
end

-- 清理所有旋转信息
function _RotateScreen:clearRotateData()
    -- 是否发生旋转
    self.m_isRotated = false
    -- 旋转队列，处理多次旋转
    self.m_rotateList = {}
end

--保存之前的方向
function _RotateScreen:setPrePortraitFlag(flag)
    self.preProtraitFlag = flag
end

function _RotateScreen:getPrePortraitFlag()
    return self.preProtraitFlag
end

-- 是否旋转
function _RotateScreen:isRotated()
    return self.m_isRotated or false
end

-- 获得当前旋转信息
function _RotateScreen:getCurRotateInfo()
    local _count = #self.m_rotateList
    if _count > 0 then
        return self.m_rotateList[_count]
    else
        return nil
    end
end

-- 获得有效的旋转信息
function _RotateScreen:getValidRotateInfo()
    for i = #self.m_rotateList, 1, -1 do
        local info = self.m_rotateList[i]

        if info.rotateRef > 0 then
            return info
        end
    end
end

-- 添加旋转信息
function _RotateScreen:addRotateInfo(isPortrait)
    local _info = clone(rotateInfo)
    local _curInfo = self:getCurRotateInfo()
    if not _curInfo then
        _info.rotateId = 1
    else
        _info.rotateId = _curInfo.rotateId + 1
    end
    _info.rotateDir = getRotateDir(isPortrait)
    _info.rotateRef = 1

    table.insert(self.m_rotateList, _info)
end

-- 更新旋转信息
function _RotateScreen:updateRotateInfo(rotateId, change)
    for i = #self.m_rotateList, 1, -1 do
        local info = self.m_rotateList[i]
        if info.rotateId == rotateId then
            info.rotateRef = info.rotateRef + change
            if info.rotateRef <= 0 then
                -- table.remove(self.m_rotateList, i)
                break
            end
        end
    end
end

-- 初始旋转信息
function _RotateScreen:initScreenDir()
    self.m_initPortraitDir = globalData.slotRunData.isPortrait or false

    self:clearRotateData()
end

-- 屏幕是否竖屏
function _RotateScreen:isPortraitScreen()
    local dirInfo = self:getValidRotateInfo()
    if dirInfo then
        if dirInfo.rotateDir == "Portrait" then
            return true
        else
            return false
        end
    else
        return self.m_initPortraitDir
    end
end

-- 注册界面旋转信息
function _RotateScreen:onRegister(isLandscapeLayer, clsName)
    local isPortraitLayer = (not isLandscapeLayer)

    -- local isPortrait = globalData.slotRunData.isPortrait
    local isPortrait = self:isPortraitScreen()
    if isPortrait ~= isPortraitLayer then
        -- 与当前旋转不同，添加新旋转信息
        self:addRotateInfo(isPortraitLayer)
        -- 旋转屏幕
        local isRotate = self:toRotateScreen(isPortraitLayer)
        return isRotate
    else
        if self.m_isRotated then
            local _curInfo = self:getCurRotateInfo()
            if _curInfo then
                -- 已经旋转，引用计数+1
                _curInfo.rotateRef = _curInfo.rotateRef + 1
            end
        end
        return false
    end
end

-- 移除界面旋转信息
function _RotateScreen:onRemove(isLandscapeLayer, rotateId, clsName)
    if self.m_isRotated then
        self:updateRotateInfo(rotateId, -1)
    end

    -- local _rotateInfo = self:getCurRotateInfo()
    -- if self.m_isRotated and (not _curRotateInfo or getRotateDir(globalData.slotRunData.isPortrait) ~= _curRotateInfo.rotateDir) then
    --     -- 转回屏幕
    --     self:resetPortraitOrLandscape(_curRotateInfo)
    --     return true
    -- else
    --     return false
    -- end

    -- 找到有效的旋转信息
    local _rotateInfo = self:getValidRotateInfo()
    -- self:onCleanup()
    -- local _rotateInfo = self:getCurRotateInfo()
    return self:checkResetRotate(_rotateInfo)
end

-- 整理旋转数据
function _RotateScreen:onCleanup()
    for i = #self.m_rotateList, 1, -1 do
        local info = self.m_rotateList[i]

        if info.rotateRef <= 0 then
            table.remove(self.m_rotateList, i)
        end
    end
end

-- 旋转屏幕
function _RotateScreen:toRotateScreen(toPortrait)
    if toPortrait == globalData.slotRunData.isPortrait then
        return false
    end

    if not self.m_isRotated then
        -- 记录初始屏幕模式
        self:setPrePortraitFlag(not toPortrait)

        self.m_isRotated = true
    end

    -- globalPlatformManager:setScreenRotateAnimFlag(false)
    -- 转竖屏
    globalData.slotRunData:changeScreenOrientation(toPortrait)

    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROTATE_SCREEN)
        end
    )

    return true
end

-- 检查是否重置旋转
function _RotateScreen:checkResetRotate(rotateInfo)
    if self.m_isRotated and (not rotateInfo or getRotateDir(globalData.slotRunData.isPortrait) ~= rotateInfo.rotateDir) then
        return true
    else
        return false
    end
end

-- 重置横竖屏
function _RotateScreen:resetPortraitOrLandscape()
    self:onCleanup()

    local _curRotateInfo = self:getCurRotateInfo()
    if not self:checkResetRotate(_curRotateInfo) then
        return
    end

    -- globalPlatformManager:setScreenRotateAnimFlag(false)

    if not _curRotateInfo then
        self.m_isRotated = false

        -- 转回原来的屏幕
        globalData.slotRunData:changeScreenOrientation(self:getPrePortraitFlag())
    else
        globalData.slotRunData:changeScreenOrientation(isPortraitDir(_curRotateInfo.rotateDir))
    end
    -- self:checkResetPosRotateShowUI()
    util_nextFrameFunc(
        function()
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROTATE_RESET_TO_PORTRAIT)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_SCREEN)
        end
    )
end

return _RotateScreen
