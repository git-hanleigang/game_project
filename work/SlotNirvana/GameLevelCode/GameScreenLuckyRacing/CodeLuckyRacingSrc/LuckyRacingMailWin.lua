---
local LuckyRacingMailWin = class("LuckyRacingMailWin", util_require("base.BaseView"))

function LuckyRacingMailWin:initUI(params)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self.m_machine = params.machine
    local resourceFilename = "LuckyRacing/Congratulations_bufa.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true

    local light = util_createAnimation("LuckyRacing/WinnerTakeAll_guang.csb")
    light:runCsbAction("idle",true)
    self:findChild("Node_guang"):addChild(light)
end
function LuckyRacingMailWin:setFunc(_func)
    self.m_func = _func
end
function LuckyRacingMailWin:initViewData(coins)
    self:runCsbAction("start",false,function()
        self.m_click = false
        self:runCsbAction("idle", true, nil, 60)
    end,60)

    local m_lb_coins = self:findChild("BitmapFontLabel_3")
    m_lb_coins:setString(util_formatCoins(coins, 50))
    self:updateLabelSize({label = m_lb_coins, sx = 1, sy = 1}, 665)
end

function LuckyRacingMailWin:onEnter()
    LuckyRacingMailWin.super.onEnter(self)
end

function LuckyRacingMailWin:onExit()
    LuckyRacingMailWin.super.onExit(self)
    
end

function LuckyRacingMailWin:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_click = true
        self:sendCollectMail()
    end
end

function LuckyRacingMailWin:closeUI()
    self:runCsbAction("over",false,function()
        if self.m_func then
            self.m_func()
        end
        self:removeFromParent()
    end,60)
end


function LuckyRacingMailWin:sendCollectMail()
    local gameName = self.m_machine:getNetWorkModuleName()
    --参数传-1位领取所有奖励,领取当前奖励传数组最后一位索引
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,-1,function(data)
        if not tolua.isnull(self) then
            self:changeSuccess()
        end
    end,function(errorCode, errorData)
        self:changeFailed()
    end)
end

function LuckyRacingMailWin:changeSuccess()
    self:closeUI()
end

function LuckyRacingMailWin:changeFailed()
end

return LuckyRacingMailWin
