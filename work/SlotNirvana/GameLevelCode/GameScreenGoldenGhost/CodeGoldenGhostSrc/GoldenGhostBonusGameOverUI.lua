
local GoldenGhostBonusGameOverUI = class("GoldenGhostBonusGameOverUI", util_require("base.BaseView"))

function GoldenGhostBonusGameOverUI:runAniIdle( )
    self:runCsbAction("idle", true)
end

function GoldenGhostBonusGameOverUI:initUI()
    self:createCsbNode("GoldenGhost/GoldenGhost_BonusGameOver.csb")
    self.m_lb_score = self:findChild("m_lb_coins")
    self.btnCollect = self:findChild("Button_collect")
    -- 先注释
    -- self:runCsbAction(
    --     "start",
    --     false,
    --     function()
    --         self:runAniIdle( )
    --     end
    -- )
end

function GoldenGhostBonusGameOverUI:setExtraInfo(game,callBack)
    self.game = game
    self.callBack = callBack

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    local winAmount = game:getWinAmount() - lastWinCoin
    self.m_lb_score:setString(util_formatCoins(winAmount,20))
    self:updateLabelSize({label = self.m_lb_score,sx = 1,sy = 1},721)
    -- 底栏赢钱 修改为:不计算 连线赢钱
    globalData.slotRunData.lastWinCoin = winAmount
    -- globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + winAmount
    game.m_machine.m_bottomUI:notifyUpdateWinLabel(winAmount,false,true)
end
-- 接口不会掉用了 不注释也行
function GoldenGhostBonusGameOverUI:clickFunc(sender)
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

return GoldenGhostBonusGameOverUI