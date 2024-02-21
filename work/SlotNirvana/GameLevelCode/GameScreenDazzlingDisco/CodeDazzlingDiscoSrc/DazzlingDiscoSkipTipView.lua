---
--xcyy
--2018年5月23日
--DazzlingDiscoSkipTipView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoSkipTipView = class("DazzlingDiscoSkipTipView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_WATCH     =   1001    --观看
local BTN_TAG_LEAVE     =   1002    --离开


function DazzlingDiscoSkipTipView:initUI(params)
    local machineRootScale = params.machineRootScale
    self.m_callFunc = params.func

    self:createCsbNode("DazzlingDisco/SociaWatchOrSpin.csb")

    self:findChild("root"):setScale(machineRootScale)

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:findChild("node_mask"):addChild(self.m_mask)

    self.m_mask:runCsbAction("animation0")

    local btn_watch = self:findChild("btn_watch")
    local btn_leave = self:findChild("btn_leave")
    btn_watch:setTag(BTN_TAG_WATCH)
    btn_leave:setTag(BTN_TAG_LEAVE)

    self:runCsbAction("start",false,function()
        
    end)
    
end

--[[
    点击按钮
]]
function DazzlingDiscoSkipTipView:clickFunc(sender)
    if self.m_isClick then
        return
    end
    self.m_isClick = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)

    self.m_mask:runCsbAction("animation2")

    local tag = sender:getTag()

    self:runCsbAction("over",false,function()
        if type(self.m_callFunc) == "function" then
            self.m_callFunc(tag == BTN_TAG_LEAVE)
        end

        self:removeFromParent()
    end)

    
end




return DazzlingDiscoSkipTipView