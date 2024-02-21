--[[
    推荐关卡展示
    author: 徐袁
    time: 2021-07-21 16:55:28
]]
-- 起始偏移
local StartOffset = 55
-- 结束偏移
local EndOffset = 45
-- 关卡宽度
local LevelLen = 210
local LevelSpace = 15

local LevelRecmdShowNode = class("LevelRecmdShowNode", util_require("base.BaseView"))

function LevelRecmdShowNode:initUI(info)
    self.m_levelPosX = {}
    self.m_levelNodes = {}
    self.m_info = info

    LevelRecmdShowNode.super.initUI(self)

    self:initView()
end

function LevelRecmdShowNode:getCsbName()
    return "newIcons/LevelRecmd2023/2023LevelFolder_jiantou.csb"
end

function LevelRecmdShowNode:initCsbNodes()
    self.m_imgLevels = self:findChild("Image_1")
    self.m_nodeTitle = self:findChild("node_title")
end

function LevelRecmdShowNode:initView()
    self:initLevelsPosition()
end

function LevelRecmdShowNode:initLevelsPosition()
    local levelInfos = self:getLevelInfos()
    local count = #levelInfos
    for i = 1, count do
        local posX = StartOffset + (LevelLen / 2) + (i - 1) * (LevelLen + LevelSpace)
        self.m_levelPosX[i] = posX
    end
end

function LevelRecmdShowNode:createTitle()
    local titleNode = nil
    local resPath = self.m_info:getTitleRes()
    if resPath and resPath ~= "" and util_IsFileExist(resPath) then
        if self.m_info:getTitleType() == "Jackpot" then
            local luaName = self.m_info:getJackpotTitleLuaName()
            if luaName then
                titleNode = util_createView("views.lobby." .. luaName, resPath, self.m_info)
            end
        end
    end
    return titleNode
end

function LevelRecmdShowNode:updateUI()
end

function LevelRecmdShowNode:getLevelInfos()
    return self.m_info.levelInfos or {}
end

function LevelRecmdShowNode:createLevel(info, offx, offy, index)
    local node = nil

    node = util_createView("views.lobby.LevelNode")
    node:refreshInfo(info, index)
    -- self:addChild(node, -1)
    node:setScale(0.83)
    node:setPosition(offx, offy - 15)

    return node
end

function LevelRecmdShowNode:getContentLen()
    local levelInfos = self:getLevelInfos()
    local count = #levelInfos
    if count > 0 then
        local totalLen = StartOffset + LevelLen * count + (count - 1) * LevelSpace + EndOffset
        return totalLen
    else
        return 0
    end
end

-- 显示关卡
function LevelRecmdShowNode:showLevels(callback)
    local _size = self.m_imgLevels:getContentSize()
    local _len = self:getContentLen()
    self.m_imgLevels:setContentSize(cc.size(_len, _size.height))

    local levelInfos = self:getLevelInfos()
    local group = self.m_info:getGroup()
    local recmdName = self.m_info:getRecmdName()
    for i = 1, #levelInfos do
        local levelInfo = levelInfos[i]
        local levelNode = self.m_levelNodes[i]
        if not levelNode then
            levelNode = self:createLevel(levelInfo, self.m_levelPosX[i], _size.height / 2, i)
            levelNode:setSiteInfo(RecmdGroup[group], recmdName)
            self.m_imgLevels:addChild(levelNode)
            self.m_levelNodes[i] = levelNode
        end
        levelNode:setVisible(true)
    end

    -- title
    if self.m_info:getTitleType() then
        if not self.m_title then
            local title = self:createTitle()
            if title then
                self.m_nodeTitle:addChild(title)
                title:setPosition(cc.p(-1 * _len / 2, _size.height / 2))
                self.m_title = title
            end
        end
    end
end

-- 隐藏关卡
function LevelRecmdShowNode:hideLevels(callback)
    for i = 1, #self.m_levelNodes do
        local levelNode = self.m_levelNodes[i]
        if levelNode then
            levelNode:setVisible(false)
        end
    end
end

-- 更新高倍场状态
function LevelRecmdShowNode:updateDeluxeLevels(_bOpenDeluxe)
    for k, value in pairs(self.m_levelNodes) do
        if value then
            value:updateDeluxeLevels(_bOpenDeluxe)
        end
    end
end

-- 更新关卡logo显示
function LevelRecmdShowNode:updateLevelLogo()
    for i = 1, #self.m_levelNodes do
        local _node = self.m_levelNodes[i]
        if _node then
            _node:updateLevelLogo(true)
        end
    end
end

return LevelRecmdShowNode
