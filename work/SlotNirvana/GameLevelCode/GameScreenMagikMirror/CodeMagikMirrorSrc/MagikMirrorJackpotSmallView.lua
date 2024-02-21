---
--xcyy
--2018年5月23日
--MagikMirrorJackpotSmallView.lua
local PublicConfig = require "MagikMirrorPublicConfig"
local MagikMirrorJackpotSmallView = class("MagikMirrorJackpotSmallView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini  = 4
}
function MagikMirrorJackpotSmallView:initUI(params)
    

    self:createCsbNode("MagikMirror_qipan_jackpot_1.csb")

end

function MagikMirrorJackpotSmallView:initViewUi(jackpotType)
    local viewType = string.lower(jackpotType) 
    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("jackpot_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end

    self:showView()
end

function MagikMirrorJackpotSmallView:updateViewUi(jackpotType)
    local viewType = string.lower(jackpotType) 
    local jackpotIndex = JACKPOT_INDEX[viewType]
    self.m_jackpotIndex = jackpotIndex
    
    --设置控件显示
    for jpType,index in pairs(JACKPOT_INDEX) do
        local node = self:findChild("jackpot_"..jpType)
        if node then
            node:setVisible(viewType == jpType)
        end
    end
end


--[[
    显示界面
]]
function MagikMirrorJackpotSmallView:showView()
    -- util_setCascadeOpacityEnabledRescursion(self, true)
    -- util_setCascadeColorEnabledRescursion(self, true)
    self:runCsbAction("start")
end

function MagikMirrorJackpotSmallView:changeLight(isShow)
    if isShow then
        self:findChild("jackpot_bglignt"):setVisible(true)
    else
        self:findChild("jackpot_bglignt"):setVisible(false)
    end
end

function MagikMirrorJackpotSmallView:showAct(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MagikMirror_jackpot_actionframe)
    self:runCsbAction("actionframe",false,function ()
        if type(func) == "function" then
            func()
        end
    end)
end
--[[
    关闭界面
]]
function MagikMirrorJackpotSmallView:showOver(func)
    self:runCsbAction("over",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

return MagikMirrorJackpotSmallView