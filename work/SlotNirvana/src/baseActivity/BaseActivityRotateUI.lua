--[[
    author:JohnnyFred
    time:2020-07-15 21:53:40
]]
local BaseView = util_require("base.BaseView")
local BaseActivityRotateUI = class("BaseActivityRotateUI", BaseView)

function BaseActivityRotateUI:ctor()
    BaseView.ctor(self)
    --竖版关卡横屏后打开的UI列表
    self.rotateShowUIMap = {}
end

function BaseActivityRotateUI:initUI(param)
    self.param = param
    self:checkPortraitOrLandscape()
    self:mergeRotateShowUIMap()
end

function BaseActivityRotateUI:mergeRotateShowUIMap()
    local param = self.param
    if param ~= nil then
        local preUI = param.preUI
        if preUI ~= nil then
            table.merge(self.rotateShowUIMap,preUI:getRotateShowUIMap())
        end
    end
end

--保存之前的方向
function BaseActivityRotateUI:setPrePortraitFlag(flag)
    self.preProtraitFlag = flag
end

function BaseActivityRotateUI:getPrePortraitFlag()
    return self.preProtraitFlag
end

function BaseActivityRotateUI:getRotateShowUIMap()
    return self.rotateShowUIMap
end

function BaseActivityRotateUI:registerListener()
    gLobalNoticManager:addObserver(self,
    function(target,data)
        if not tolua.isnull(self) then
            self:checkAddRotateShowUI(data.node)
        end
    end,ViewEventType.NOTIFY_SHOW_UI)
end

function BaseActivityRotateUI:checkPortraitOrLandscape()
    if self:isGameIsLandscape() then
        local param = self.param
        if param ~= nil and param.preUI ~= nil then
            self:setPrePortraitFlag(param.preUI:getPrePortraitFlag())
        else
            self:setPrePortraitFlag(globalData.slotRunData.isPortrait)
        end
        globalPlatformManager:setScreenRotateAnimFlag(false)
        globalData.slotRunData:changeScreenOrientation(false)
    end
end

function BaseActivityRotateUI:checkBackToPortraitOrLandscape()
    if self:isGameIsLandscape() then
        globalPlatformManager:setScreenRotateAnimFlag(false)
        globalData.slotRunData:changeScreenOrientation(self:getPrePortraitFlag())
        self:checkResetPosRotateShowUI()
    end
end

--检查添加旋转后关卡中创建的UI
function BaseActivityRotateUI:checkAddRotateShowUI(node)
    if node ~= nil and self:isGameIsLandscape() then
        self.rotateShowUIMap[node] = true
        addExitListenerNode(node,
        function()
            if self.rotateShowUIMap ~= nil then
                self.rotateShowUIMap[node] = nil
            end
        end)
    end
end

--关闭后关卡中创建的UI坐标是按照横屏添加的，需要还原到竖版关卡对应的坐标
function BaseActivityRotateUI:checkResetPosRotateShowUI()
    local rotateShowUIMap = self.rotateShowUIMap
    if globalData.slotRunData.isPortrait and rotateShowUIMap ~= nil then
        local dis = (display.width - display.height) / 2
        for k,v in pairs(rotateShowUIMap) do
            if not tolua.isnull(k) then
                local vPosX,vPosY = k:getPosition()
                k:setPosition(vPosX + dis,vPosY - dis)
                if k.getRotateBackScaleFlag ~= nil and k.m_csbNode ~= nil and k:getRotateBackScaleFlag() then
                    util_portraitAdaptPortrait(k.m_csbNode)
                end
            end
            rotateShowUIMap[k] = nil
        end
    end
end

--进游戏是否需要旋转到横屏
function BaseActivityRotateUI:isGameIsLandscape()
    return true
end
return BaseActivityRotateUI
