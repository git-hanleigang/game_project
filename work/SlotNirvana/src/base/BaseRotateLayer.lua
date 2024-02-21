--[[
    旋转界面的图层基类
    author: 徐袁
    time: 2021-01-23 17:11:23
]]
local BaseRotateLayer = class("BaseRotateLayer", BaseLayer)

function BaseRotateLayer:ctor()
    BaseRotateLayer.super.ctor(self)
    self.m_rotateId = 0
    self.m_isCurRotated = false
end

function BaseRotateLayer:initUI(...)
    self.m_isCurRotated = RotateScreen:getInstance():onRegister(self:isLandscape())

    local _info = RotateScreen:getInstance():getCurRotateInfo()
    if _info then
        self.m_rotateId = _info.rotateId
    end

    -- if RotateScreen:getInstance():isRotated() then
    --     -- 竖屏旋转成横屏不播放动画
    --     self:setShowActionEnabled(false)
    --     self:setHideActionEnabled(false)
    -- end

    BaseRotateLayer.super.initUI(self, ...)
end

function BaseRotateLayer:onEnter()
    BaseRotateLayer.super.onEnter(self)

    -- if RotateScreen:getInstance():isRotated() then
    if self.m_isCurRotated then
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    end

    self.m_isCurRotated = false
end

function BaseRotateLayer:closeUI(callback, ...)
    -- if RotateScreen:getInstance():isRotated() then
    --     -- 竖屏旋转成横屏不播放动画
    --     self:setShowActionEnabled(false)
    --     self:setHideActionEnabled(false)

    -- -- gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    -- end
    self.m_isCurRotated = RotateScreen:getInstance():onRemove(self:isLandscape(), self.m_rotateId)

    local _callback = function()
        if callback then
            callback()
        end
        if self.m_isCurRotated then
            RotateScreen:getInstance():resetPortraitOrLandscape()
            self.m_isCurRotated = false
        end
    end
    BaseRotateLayer.super.closeUI(self, _callback, ...)
end

-- function BaseRotateLayer:onExit()
--     RotateScreen:getInstance():onRemove(self:isLandscape(), self.m_rotateId)
--     BaseRotateLayer.super.onExit(self)
-- end

-- 是否播放显示动画
function BaseRotateLayer:isShowActionEnabled()
    if self.m_isCurRotated then
        return false
    end

    return BaseRotateLayer.super.isShowActionEnabled(self)
end

-- 是否播放隐藏动画
function BaseRotateLayer:isHideActionEnabled()
    if self.m_isCurRotated then
        return false
    end

    return BaseRotateLayer.super.isHideActionEnabled(self)
end

-- 界面是否横屏
function BaseRotateLayer:isLandscape()
    return true
end

-- 界面 是否在旋转队列里
function BaseRotateLayer:checkCurLayerNeedRotate()
    return self.m_rotateId ~= 0
end

return BaseRotateLayer
