---
--xcyy
--2018年5月23日
--BunnysLockJackpotBar.lua

local BunnysLockJackpotBar = class("BunnysLockJackpotBar",util_require("Levels.BaseLevelDialog"))

function BunnysLockJackpotBar:initUI(params)
    self.m_parentView = params.parentView
    self.m_machine = params.machine
    self:createCsbNode("JackpotBarBunnysLock.csb")
    self.m_grandItem = util_createAnimation("JackpotBarBunnysLock_1.csb")
    self.m_majorItem = util_createAnimation("JackpotBarBunnysLock_2.csb")
    self.m_minorItem = util_createAnimation("JackpotBarBunnysLock_3.csb")
    self.m_miniItem = util_createAnimation("JackpotBarBunnysLock_4.csb")

    self:addChild(self.m_grandItem)
    self:addChild(self.m_majorItem)
    self:addChild(self.m_minorItem)
    self:addChild(self.m_miniItem)
    self.m_curCollectCount = {
        grand = 0,
        major = 0,
        minor = 0,
        mini = 0
    }

    self.m_jackpotItems = {
        grand = self.m_grandItem,
        major = self.m_majorItem,
        minor = self.m_minorItem,
        mini = self.m_miniItem
    }

    self:resetView()
end

function BunnysLockJackpotBar:onEnter()

    BunnysLockJackpotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function BunnysLockJackpotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_grandItem:findChild("m_lb_coins"),1,true)
    self:changeNode(self.m_majorItem:findChild("m_lb_coins"),2,true)
    self:changeNode(self.m_minorItem:findChild("m_lb_coins"),3)
    self:changeNode(self.m_miniItem:findChild("m_lb_coins"),4)

    self:updateSize()
end

function BunnysLockJackpotBar:updateSize()

    local label1=self.m_grandItem:findChild("m_lb_coins")
    local label2=self.m_majorItem:findChild("m_lb_coins")
    local info1={label=label1,sx=0.52,sy=0.52}
    local info2={label=label2,sx=0.52,sy=0.52}
    local label3=self.m_minorItem:findChild("m_lb_coins")
    local info3={label=label3,sx=0.52,sy=0.52}
    local label4=self.m_miniItem:findChild("m_lb_coins")
    local info4={label=label4,sx=0.52,sy=0.52}
    self:updateLabelSize(info1,404)
    self:updateLabelSize(info2,386)
    self:updateLabelSize(info3,356)
    self:updateLabelSize(info4,327)
end

function BunnysLockJackpotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    重置界面
]]
function BunnysLockJackpotBar:resetView()
    for key,item in pairs(self.m_jackpotItems) do
        for index = 1,3 do
            -- item:findChild("egg_"..index):setVisible(false)
            item:findChild("egg_lizi"..index):setVisible(false)
        end
        item:findChild("zhongjiang"):setVisible(false)
        item:runCsbAction("idleframe",true)
    end

    self.m_curCollectCount = {
        grand = 0,
        major = 0,
        minor = 0,
        mini = 0
    }
end

function BunnysLockJackpotBar:refreshUI(jackpot)
    self.m_curCollectCount[jackpot] = self.m_curCollectCount[jackpot] + 1

    local count = self.m_curCollectCount[jackpot]
    local item = self.m_jackpotItems[jackpot]

    item:findChild("egg_lizi"..count):setVisible(true)
    item:findChild("egg_lizi"..count):resetSystem()
    item:runCsbAction("shouji"..count,false,function()
        if count == 3 then
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_hit_jp.mp3")
            item:runCsbAction("actionframe",true)
            item:findChild("zhongjiang"):setVisible(true)
        else
            item:runCsbAction("idleframe"..(count + 2),true)
        end
        
    end)

    return count == 3
end

function BunnysLockJackpotBar:getCurJackpotNode(jackpot)
    local count = self.m_curCollectCount[jackpot] + 1
    local item = self.m_jackpotItems[jackpot]
    return item:findChild("egg_"..count)
end

return BunnysLockJackpotBar