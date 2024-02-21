---
--xcyy
--2018年5月23日
--BunnysLockColorfulItem.lua

local BunnysLockColorfulItem = class("BunnysLockColorfulItem",util_require("Levels.BaseLevelDialog"))

function BunnysLockColorfulItem:initUI(params)
    self.m_parentView = params.parentView
    self:createCsbNode("BunnysLock_BonusGameEgg.csb")

    self.m_egg_mini = self:findChild("mini")
    self.m_egg_minor = self:findChild("minor")
    self.m_egg_major = self:findChild("major")
    self.m_egg_grand = self:findChild("grand")

    self.m_egg_mini:setVisible(false)
    self.m_egg_minor:setVisible(false)
    self.m_egg_major:setVisible(false)
    self.m_egg_grand:setVisible(false)

    self.m_layout = self:findChild("click")
    self:addClick(self.m_layout)

    self.m_curJackpot = ""

    self.m_isClicked = false
end

function BunnysLockColorfulItem:changeTouchEnable(enable)
    self.m_layout:setTouchEnabled(enable)
end

function BunnysLockColorfulItem:resetStatus()
    self:runCsbAction("idle",true)
    self:changeTouchEnable(true)
    self.m_isClicked = false

    self.m_curJackpot = ""

    self.m_egg_mini:setVisible(false)
    self.m_egg_minor:setVisible(false)
    self.m_egg_major:setVisible(false)
    self.m_egg_grand:setVisible(false)
end

--默认按钮监听回调
function BunnysLockColorfulItem:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
    
    self.m_parentView:clickFunc(self)
end

function BunnysLockColorfulItem:refreshUI(jackpotType,func)
    self.m_isClicked = true
    self:changeTouchEnable(false)
    if jackpotType == "grand" then
        self.m_egg_grand:setVisible(true)
    elseif jackpotType == "major" then
        self.m_egg_major:setVisible(true)
    elseif jackpotType == "minor" then
        self.m_egg_minor:setVisible(true)
    else
        self.m_egg_mini:setVisible(true)
    end
    self.m_curJackpot = jackpotType

    self:runCsbAction("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function BunnysLockColorfulItem:turnToDark(jackpotType,leftType)
    if leftType and leftType ~= "" then
        self.m_curJackpot = leftType
        if leftType == "grand" then
            self.m_egg_grand:setVisible(true)
        elseif leftType == "major" then
            self.m_egg_major:setVisible(true)
        elseif leftType == "minor" then
            self.m_egg_minor:setVisible(true)
        else
            self.m_egg_mini:setVisible(true)
        end
        self:runCsbAction("idle3")
    end
    if self.m_curJackpot ~= jackpotType then
        self:runCsbAction("dark")
    end
end

return BunnysLockColorfulItem