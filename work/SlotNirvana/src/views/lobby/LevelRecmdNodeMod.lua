--[[
    推荐关卡 模组
]]
local LevelRecmdNodeMod = class("LevelRecmdNodeMod", util_require("base.BaseView"))

-- 关卡宽度
local LevelLen = 220

function LevelRecmdNodeMod:initDatas(info)
    self.m_contentLen = 0
    self.m_info = info
    self.m_group = self.m_info:getRecmdName()
    self.m_levelPosX = {}
    self.m_levelNodes = {}
end

function LevelRecmdNodeMod:initUI()
    LevelRecmdNodeMod.super.initUI(self)
    self:initView()
end

function LevelRecmdNodeMod:getCsbName()
    return "newIcons/SlotsMod/LevelRecmdNodeMod.csb"
end

function LevelRecmdNodeMod:initCsbNodes()
    self.m_nodeBG = self:findChild("Node_bg")
    self.m_nodeLevel = self:findChild("Node_level")
    self.m_nodeTitle = self:findChild("Node_title")
end

function LevelRecmdNodeMod:initView()
    self:initBg()
    self:createTitle()
    self:initLevelsPosition()
    self:initLevel()
    self:playIdle()
end

function LevelRecmdNodeMod:initBg()
    local _csb = self.m_info:getCsb()
    self.m_titleNode, self.m_titleAct = util_csbCreate(_csb)
    self.m_nodeBG:addChild(self.m_titleNode)
    self.m_sp_bg = self.m_titleNode:getChildByName("node_mid"):getChildByName("sp_bg")
end

function LevelRecmdNodeMod:createTitle()
    local resPath = self.m_info:getTitleRes()
    if resPath and resPath ~= "" and util_IsFileExist(resPath) then
        if self.m_info:getTitleType() == "Jackpot" then
            local luaName = self.m_info:getJackpotTitleLuaName()
            if luaName then
                local titleNode = util_createView("views.lobby." .. luaName, resPath, self.m_info)
                if titleNode then
                    self.m_nodeTitle:addChild(titleNode)
                end
            end
        end
    end
end

function LevelRecmdNodeMod:initLevelsPosition()
    local levelInfos = self:getLevelInfos()
    local count = #levelInfos
    for i = 1, count do
        local posX = -((count / 2) - 0.5) * LevelLen + LevelLen * (i - 1)
        self.m_levelPosX[i] = posX
    end
end

function LevelRecmdNodeMod:initLevel()
    local levelInfos = self:getLevelInfos()
    local group = self.m_info:getGroup()
    local recmdName = self.m_info:getRecmdName()
    for i = 1, #levelInfos do
        local levelInfo = levelInfos[i]
        local levelNode = self.m_levelNodes[i]
        if not levelNode then
            levelNode = self:createLevel(levelInfo, self.m_levelPosX[i], 0, i)
            levelNode:setSiteInfo(RecmdGroup[group], recmdName)
            self.m_nodeLevel:addChild(levelNode)
            self.m_levelNodes[i] = levelNode
        end
        levelNode:setVisible(true)
    end
end

function LevelRecmdNodeMod:createLevel(info, offx, offy, index)
    local scale = info.isSmall and 0.83 or 0.95
    local offsetY = info.isSmall and -15 or 0
    local node = util_createView("views.lobby.LevelNode")
    node:refreshInfo(info, index)
    node:setScale(scale)
    node:setPosition(offx, offy + offsetY)
    return node
end

function LevelRecmdNodeMod:getLevelInfos()
    return self.m_info.levelInfos or {}
end

function LevelRecmdNodeMod:getContentLen()
    if self.m_sp_bg then
        local contentSize = self.m_sp_bg:getContentSize()
        return contentSize.width / 2
    end
    return 0
end

-- 在滑动过程中偏移xx，下一个出现or消失
function LevelRecmdNodeMod:getOffsetPosX()
    return self:getContentLen() --200
end

function LevelRecmdNodeMod:onEnter()
    LevelRecmdNodeMod.super.onEnter(self)
end

-- 更新高倍场状态
function LevelRecmdNodeMod:updateDeluxeLevels(_bOpenDeluxe)
    for k, value in pairs(self.m_levelNodes) do
        if value then
            value:updateDeluxeLevels(_bOpenDeluxe)
        end
    end
end

-- 更新关卡logo显示
function LevelRecmdNodeMod:updateLevelLogo()
    for i = 1, #self.m_levelNodes do
        local _node = self.m_levelNodes[i]
        if _node then
            _node:updateLevelLogo(true)
        end
    end
end

function LevelRecmdNodeMod:isNeedUpdateLogo()
    return true
end

function LevelRecmdNodeMod:playIdle()
    util_csbPlayForKey(self.m_titleAct, "idle", true)
end

return LevelRecmdNodeMod
