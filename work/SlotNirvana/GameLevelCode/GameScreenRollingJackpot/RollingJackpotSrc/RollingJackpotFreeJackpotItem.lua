---
--xcyy
--2018年5月23日
--RollingJackpotFreeJackpotItem.lua

local RollingJackpotFreeJackpotItem = class("RollingJackpotFreeJackpotItem",util_require("Levels.BaseLevelDialog"))
-- local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
-- local SoundConfig = ConfigInstance.SoundConfig
local ITMETYPE = {
    NORMAL = 1,  --普通的
    NEXT = 2,    --下次的
    CURRENT = 3 --当前的
}
local coins_infos = {
    {pos = cc.p(0, 16), fontInfo = "RollingJackpotFont/RollingJackpot_font_09.fnt"},
    {pos = cc.p(0, 16), fontInfo = "RollingJackpotFont/RollingJackpot_font_08.fnt"},
    {pos = cc.p(0, 16), fontInfo = "RollingJackpotFont/RollingJackpot_font_07.fnt"},
    {pos = cc.p(0, 14), fontInfo = "RollingJackpotFont/RollingJackpot_font_06.fnt"},
    {pos = cc.p(0, 13), fontInfo = "RollingJackpotFont/RollingJackpot_font_05.fnt"},
    {pos = cc.p(0, 11), fontInfo = "RollingJackpotFont/RollingJackpot_font_04.fnt"},
    {pos = cc.p(0, 12), fontInfo = "RollingJackpotFont/RollingJackpot_font_03.fnt"},
    {pos = cc.p(0, 10), fontInfo = "RollingJackpotFont/RollingJackpot_font_02.fnt"},
    {pos = cc.p(0, 11), fontInfo = "RollingJackpotFont/RollingJackpot_font_01.fnt"},
}

function RollingJackpotFreeJackpotItem:initUI(index)
    self:createCsbNode("RollingJackpot_Jackpot_free_dan.csb")
    self.m_type = ITMETYPE.NORMAL
    self.m_index = index
    self:initFntFile()
    self.m_light = util_createAnimation("RollingJackpot_Jackpot_free_danL.csb")
    self:findChild("diL"):addChild(self.m_light)
    self.m_light:playAction("idle", true)
    self.m_totalWin = util_createAnimation("RollingJackpot_Free_mubiaoshu.csb")
    self:findChild("Node_zi"):addChild(self.m_totalWin)
    self.m_totalWin:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function  RollingJackpotFreeJackpotItem:initFntFile()
    local coins_info = coins_infos[self.m_index]
    if coins_info then
        self:findChild("m_lb_coins"):setFntFile(coins_info.fontInfo)
        self:findChild("m_lb_coins"):setPosition(coins_info.pos)
    end
end

function RollingJackpotFreeJackpotItem:onEnter()

end

function RollingJackpotFreeJackpotItem:showAdd()
    
end
function RollingJackpotFreeJackpotItem:onExit()
    --gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function RollingJackpotFreeJackpotItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--
function RollingJackpotFreeJackpotItem:initData(data)
    self.m_gameData = data
    if data.index ~= self.m_index then
        self.m_index = data.index
        self:initFntFile()
    end
    self:initCoins()
    self.m_totalWin:setVisible(false)
end

--初始化金币
function RollingJackpotFreeJackpotItem:initCoins()
    local data = self.m_gameData or {}
    local multiple = data.multiple
    if multiple then
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local coins = betCoin * multiple
        self:findChild("m_lb_coins"):setString(util_formatCoins(coins,40))
        self:updateLabelSize({label = self:findChild("m_lb_coins"), sx = 0.92, sy = 0.92}, 506)
    end
end

function RollingJackpotFreeJackpotItem:setItemType(typeIndex)
    self.m_type = typeIndex
end

function RollingJackpotFreeJackpotItem:playIdle()
    local idleStr = ""
    if ITMETYPE.NORMAL == self.m_type then
        idleStr = "idle3"
    elseif ITMETYPE.CURRENT == self.m_type then
        idleStr = "idle2"
    elseif ITMETYPE.NEXT == self.m_type then
        idleStr = "idle"
    end
    if idleStr ~= "" then
        self:runCsbAction(idleStr, true)
    end
end

function RollingJackpotFreeJackpotItem:showCollectFullEffect()
    self:runCsbAction("actionframe", true)
end

function RollingJackpotFreeJackpotItem:showTotalWin()
    self.m_totalWin:setVisible(true)
    self.m_totalWin:playAction("switch5")
end

return RollingJackpotFreeJackpotItem