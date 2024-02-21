---
--xcyy
--2018年5月23日
--JackpotElvesJackPotBarInColorful.lua

local JackpotElvesJackPotBarInColorful = class("JackpotElvesJackPotBarInColorful",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "JackpotElvesPublicConfig"

local JACKPOT_CSB_NAMES = {
    epic = "JackpotElves_jackpot_epic.csb",
    grand = "JackpotElves_jackpot_grand.csb",
    ultra = "JackpotElves_jackpot_ultra.csb",
    mega = "JackpotElves_jackpot_mega.csb",
    major = "JackpotElves_jackpot_major.csb",
    minor = "JackpotElves_jackpot_minor.csb",
    mini = "JackpotElves_jackpot_mini.csb" 
}

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

function JackpotElvesJackPotBarInColorful:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("JackpotElves_jackpot_pick.csb")

    --按照索引存
    self.m_jackpotsItem = {}
    --按类型存
    self.m_jackpotsItemByType = {}

    for index,jackpotType in pairs(JACKPOT_TYPE) do
        local parentNode = self:findChild("Node_"..jackpotType)
        if parentNode then
            local item = util_createView("CodeJackpotElvesBonusGame.JackpotElvesJackPotBarItem",{
                csbName = JACKPOT_CSB_NAMES[jackpotType],
                jackpotType = jackpotType
            })
            parentNode:addChild(item)
            self.m_jackpotsItem[index] = item
            self.m_jackpotsItemByType[jackpotType] = item
        end
    end

end



function JackpotElvesJackPotBarInColorful:onEnter()
    JackpotElvesJackPotBarInColorful.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotElvesJackPotBarInColorful:onExit()
    JackpotElvesJackPotBarInColorful.super.onExit(self)
end

function JackpotElvesJackPotBarInColorful:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置UI显示
]]
function JackpotElvesJackPotBarInColorful:resetUI(betLevel)
    for index,item in pairs(self.m_jackpotsItem) do
        item:resetShow()
    end
    if betLevel == 0 then
        self.m_jackpotsItemByType["epic"]:showLockIdle()
        self.m_jackpotsItemByType["grand"]:showLockIdle()
    elseif betLevel == 1 then
        self.m_jackpotsItemByType["epic"]:showLockIdle()
    end
end

-- 更新jackpot 数值信息
--
function JackpotElvesJackPotBarInColorful:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    for index,item in pairs(self.m_jackpotsItem) do
        self:changeNode(item:findChild("m_lb_coins"),index,true, item)
    end

    self:updateSize()
end

function JackpotElvesJackPotBarInColorful:updateSize()

    local label1=self.m_jackpotsItem[1]:findChild("m_lb_coins")
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,351)

    local label2=self.m_jackpotsItem[2]:findChild("m_lb_coins")
    local info2={label=label2,sx=0.93,sy=0.93}
    self:updateLabelSize(info2,351)

    local label3=self.m_jackpotsItem[3]:findChild("m_lb_coins")
    local info3={label=label3,sx=0.93,sy=0.93}
    self:updateLabelSize(info3,351)

    local label4=self.m_jackpotsItem[4]:findChild("m_lb_coins")
    local info4={label=label4,sx=0.84,sy=0.84}
    self:updateLabelSize(info4,351)

    local label5=self.m_jackpotsItem[5]:findChild("m_lb_coins")
    local info5={label=label5,sx=0.84,sy=0.84}
    self:updateLabelSize(info5,351)

    local label6=self.m_jackpotsItem[6]:findChild("m_lb_coins")
    local info6={label=label6,sx=0.75,sy=0.75}
    self:updateLabelSize(info6,351)

    local label7=self.m_jackpotsItem[7]:findChild("m_lb_coins")
    local info7={label=label7,sx=0.75,sy=0.75}
    self:updateLabelSize(info7,351)

    --压暗字体
    local label1_1=self.m_jackpotsItem[1]:findChild("m_lb_coins_0")
    local info1_1={label=label1_1,sx=1,sy=1}
    self:updateLabelSize(info1_1,351)

    local label2_1=self.m_jackpotsItem[2]:findChild("m_lb_coins_0")
    local info2_1={label=label2_1,sx=0.93,sy=0.93}
    self:updateLabelSize(info2_1,351)
end

function JackpotElvesJackPotBarInColorful:changeNode(label,index,isJump,item)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
    if index == 1 then
        item:findChild("m_lb_coins_0"):setString(util_formatCoins(value,20,nil,nil,true))
    elseif index == 2 then
        item:findChild("m_lb_coins_0"):setString(util_formatCoins(value,20,nil,nil,true))
    end
end

--[[
    中奖动画
]]
function JackpotElvesJackPotBarInColorful:showRewardAnim(jackpotType)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_jackpotShan)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:runRewardAnim()
end

--[[
    idle动画
]]
function JackpotElvesJackPotBarInColorful:showIdleAnim(jackpotType)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:runIdleAnim()
end

--[[
    取消期待动画
]]
function JackpotElvesJackPotBarInColorful:expectOverAnim(jackpotType)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:expectOverAnim()
end

--[[
    压黑动画
]]
function JackpotElvesJackPotBarInColorful:runDarkAni(jackpotType)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:showDarkAni()
end

--绿色新压黑
function JackpotElvesJackPotBarInColorful:runDarkAniForLv(jackpotType)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:showDarkAniForLv()
end

--[[
    刷新收集进度
]]
function JackpotElvesJackPotBarInColorful:refreshCollectCount(jackpotType,count,func)
    local item = self.m_jackpotsItemByType[jackpotType]
    item:updateCollectCount(count)
end
--[[
    获取jackpot的收集点
]]
function JackpotElvesJackPotBarInColorful:getJackpotCollectItem(jackpotType,count)
    local item = self.m_jackpotsItemByType[jackpotType]
    return item:getCollectItem(count)
end
--[[
    按照type获取 jackpot item
]]
function JackpotElvesJackPotBarInColorful:getItemByType(jackpotType)
    return self.m_jackpotsItemByType[jackpotType]
end

return JackpotElvesJackPotBarInColorful