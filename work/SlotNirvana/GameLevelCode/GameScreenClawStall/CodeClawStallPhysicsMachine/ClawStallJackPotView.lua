---
--xcyy
--2018年5月23日
--ClawStallJackPotView.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallJackPotView = class("ClawStallJackPotView",util_require("Levels.BaseLevelDialog"))

local BIRDS_RES = {
    "Socre_ClawStall_9",
    "Socre_ClawStall_8",
    "Socre_ClawStall_7",
    "Socre_ClawStall_6",
    "Socre_ClawStall_5"
}

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}

function ClawStallJackPotView:initUI(params)
    local viewType = params.jackpotType
    local birdType = 1--params.birdType[1]
    self.m_winCoin = params.winCoin
    self.m_endFunc = params.func
    self.m_parentView = params.parentView
    self.m_viewType = viewType
    self.m_item = params.item

    self:createCsbNode("ClawStall_Machine_JackpotWinView.csb")

    local spine = util_spineCreate(BIRDS_RES[birdType],true,true)
    self:findChild("Birds"):addChild(spine)
    self.m_spine = spine
    

    self:findChild("Grand"):setVisible(viewType == "grand")
    self:findChild("Major"):setVisible(viewType == "major")
    self:findChild("Minor"):setVisible(viewType == "minor")
    self:findChild("Mini"):setVisible(viewType == "mini")
    self:findChild("Sprite_grand"):setVisible(viewType == "grand")
    self:findChild("Sprite_major"):setVisible(viewType == "major")
    self:findChild("Sprite_minor"):setVisible(viewType == "minor")
    self:findChild("Sprite_mini"):setVisible(viewType == "mini")

    self:showView()

    local jackpotIndex = JACKPOT_INDEX[viewType]
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(self.m_winCoin,jackpotIndex)
end


--[[
    显示界面
]]
function ClawStallJackPotView:showView()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_jp_info)
    local params = {}
    params[1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            util_spinePlay(self.m_spine,"idle",true)
        end
    }
    util_runAnimations(params)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",false,function(  )
            self:showOver()
        end)
    end)
end

--[[
    关闭界面
]]
function ClawStallJackPotView:showOver()
    self:runCsbAction("over",false,function()
        self.m_parentView:flyJackpotToCollectBar(self,self.m_item,function(  )
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
        end)
        
    end)
end


return ClawStallJackPotView