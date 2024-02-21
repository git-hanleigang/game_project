--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-08 19:35:14
]]

local DazzlingDynastyBonusGameOverUI = class("DazzlingDynastyBonusGameOverUI", util_require("base.BaseView"))

function DazzlingDynastyBonusGameOverUI:initUI()
    self:createCsbNode("DazzlingDynasty/DazzlingDynasty_BonusGameOver.csb")
    self.m_lb_score = self:findChild("m_lb_coins")
    self.btnCollect = self:findChild("Button_1")
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end
    )
end

function DazzlingDynastyBonusGameOverUI:setExtraInfo(game,callBack)
    self.game = game
    self.callBack = callBack
    local winAmount = game:getWinAmount() - globalData.slotRunData.lastWinCoin
    self.m_lb_score:setString(util_formatCoins(winAmount,13))
    self:updateLabelSize({label = self.m_lb_score,sx = 1,sy = 1},721)
    globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winAmount
    game.m_machine.m_bottomUI:notifyUpdateWinLabel(winAmount,false,true)
end

function DazzlingDynastyBonusGameOverUI:clickFunc(sender)
    if sender == self.btnCollect then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.btnCollect:setEnabled(false)
        self:runCsbAction("over", false,function(  )
            self:setVisible(false)
            if self.callBack ~= nil then
                self.callBack()
            end
        end)
    end
end
return DazzlingDynastyBonusGameOverUI