--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-07-30 15:41:08
]]
local DazzlingDynastyBonusUI = class("DazzlingDynastyBonusUI", util_require("base.BaseView"))
local CodeGameScreenDazzlingDynastyMachine = util_require("GameScreenDazzlingDynasty.CodeGameScreenDazzlingDynastyMachine")

function DazzlingDynastyBonusUI:initUI()
    self:createCsbNode("DazzlingDynasty_Choose2.csb")
    self.selectedFlag = false
    self.m_lb_freegames = self:findChild("m_lb_freegames")
    self.btnBonus = self:findChild("btnBonus")
    self.btnFreeGames = self:findChild("btnFreeGames")
    self:runCsbAction(
        "show",
        false,
        function()
            if not self.selectedFlag then
                self:runCsbAction("idle", true)
            end
        end
    )
end

function DazzlingDynastyBonusUI:setExtraInfo(machine, callBack)
    self.m_machine = machine
    self.callBack = callBack
    self:__updateUI()
end

function DazzlingDynastyBonusUI:__updateUI()
    self.m_lb_freegames:setString(self.m_machine.m_runSpinResultData.p_selfMakeData.triggerTimes_FREESPIN.times)
end

function DazzlingDynastyBonusUI:__setButtonEnabled(flag)
    self.btnBonus:setEnabled(flag)
    self.btnFreeGames:setEnabled(flag)
end

function DazzlingDynastyBonusUI:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_bonusSelectItem.mp3")
    if name == "btnBonus" then
        self.selectedFlag = true
        self:__setButtonEnabled(false)
        self:runCsbAction("xuanzhong",false,
        function()
            if self.callBack ~= nil then
                self.callBack(1)
            end
        end)
    elseif name == "btnFreeGames" then
        self.selectedFlag = true
        self:__setButtonEnabled(false)
        self:runCsbAction("xuanzhong2",false,
        function()
            if self.callBack ~= nil then
                self.callBack(0)
            end
        end)
    end
end

function DazzlingDynastyBonusUI:close()
    self:removeFromParent()
end

function DazzlingDynastyBonusUI:onExit()
    
end
return DazzlingDynastyBonusUI
