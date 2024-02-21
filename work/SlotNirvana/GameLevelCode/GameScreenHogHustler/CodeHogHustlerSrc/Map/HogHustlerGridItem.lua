---
--xcyy
--2018年5月23日
--HogHustlerGridItem.lua

local HogHustlerGridItem = class("HogHustlerGridItem",util_require("Levels.BaseLevelDialog"))
local HogHustlerMapConfig = require("CodeHogHustlerSrc.HogHustlerMapConfig")


function HogHustlerGridItem:initUI(data)
    self.m_index = data.index
    self.m_isChangeBg = false --是否改变背景状态
    self.m_isCurGrid = false  --是否是当前角色所处的格子
    if self.m_index == 1 then
        self.m_gridType = HogHustlerMapConfig.GridType.Start
    else
        self.m_gridType = HogHustlerMapConfig.GridType.Common
    end
    self:createCsbNode("HogHustler_gezi.csb")
    self:initGridBg()
end

function HogHustlerGridItem:resetGridItem()
    self.m_isChangeBg = false --是否改变背景状态
    self.m_isCurGrid = false  --是否是当前角色所处的格子
    self:initGridBg()
end

function HogHustlerGridItem:onEnter()
    HogHustlerGridItem.super.onEnter(self)
end

function HogHustlerGridItem:showAdd()
    
end

function HogHustlerGridItem:onExit()
    HogHustlerGridItem.super.onExit(self)
end

--默认按钮监听回调
function HogHustlerGridItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--初始化格子背景
function HogHustlerGridItem:initGridBg()
    if self.m_gridType == HogHustlerMapConfig.GridType.Start then
        self:runCsbAction("idle4")
    else
        self:runCsbAction("idle2")
    end
end

--初始化格子的道具
function HogHustlerGridItem:initCurGridBg(isInit)
    self.m_isCurGrid = true
    self.m_isChangeBg = true
    if self.m_gridType == HogHustlerMapConfig.GridType.Common then
        if isInit then
            self:runCsbAction("idle5")
        else
            self:runCsbAction("actionframe2")
        end
    else
        if not isInit then
            self:runCsbAction("actionframe3")
        end
    end
end

--修改格子背景
function HogHustlerGridItem:changeGridBg(isEnd)
    self.m_isChangeBg = not self.m_isChangeBg
    if self.m_gridType == HogHustlerMapConfig.GridType.Common then
        if self.m_isChangeBg then
            if isEnd then
                self:runCsbAction("idle5")
            else
                self:runCsbAction("idle3")
            end
        else
            if self.m_isCurGrid then
                self:runCsbAction("over3")
                self.m_isCurGrid = false
            else
                self:runCsbAction("actionframe1")
            end
        end
    else
        if not self.m_isChangeBg and not self.m_isCurGrid then
            self:runCsbAction("actionframe3")
        end

        if self.m_isChangeBg then
            if isEnd then
                self:runCsbAction("idle7")
            else
                self:runCsbAction("idle6")
            end
        end

        self.m_isCurGrid = false
    end
end

return HogHustlerGridItem