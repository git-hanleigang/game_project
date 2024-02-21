--[[
local CherryBountyView = class("CherryBountyView", cc.Node)
local CherryBountyView = class("CherryBountyView")

function CherryBountyView:initData_(_data)
    self.m_data = _data
    self:initUI()
end
]]

local CherryBountyView = class("CherryBountyView", util_require("base.BaseView"))
local CherryBountyView = class("CherryBountyView", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CherryBountyPublicConfig"

function CherryBountyView:initUI(_data)

    self:createCsbNode("CherryBounty/xxxxxxx.csb")

    --[[
        self.m_xxxSpine = util_spineCreate(spineName, true, true)
        self.m_xxxSpine = util_spineCreate(spineName, true, false)
        self:findChild("xxx"):addChild(self.m_xxxSpine)
        util_spinePlay(self.m_xxxSpine, "idle", false)
        util_spineEndCallFunc(self.m_xxxSpine,  "idle", function() end)
    ]]
    --[[
        self.m_xxxCsb = util_createAnimation("CherryBounty_LinkLabel.csb")
        self:findChild("xxx"):addChild(self.m_xxxCsb)
        self.m_xxxCsb:runCsbAction("actionframe")
    ]]

    -- 非按钮节点 手动绑定监听
    -- self:addClick("xxx") 

    -- 延时节点
    -- local node = cc.Node:create()
    -- self:addChild(node)
    -- 延时函数
    -- self:stopAllActions()
    -- performWithDelay(self, function ()
    -- end, 0.5)

    -- 定时器
    -- schedule(view,function ()
    -- end, 0.08)

    -- 淡入淡出
    -- util_setCascadeOpacityEnabledRescursion(self, true)
end

function CherryBountyView:onEnter()
    CherryBountyView.super.onEnter(self)
    --[[
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
        end)
    ]]
end

return CherryBountyView