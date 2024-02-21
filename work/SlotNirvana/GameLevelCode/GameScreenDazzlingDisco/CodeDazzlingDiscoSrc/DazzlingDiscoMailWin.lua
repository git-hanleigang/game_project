---
local DazzlingDiscoMailWin = class("DazzlingDiscoMailWin", util_require("Levels.BaseLevelDialog"))

function DazzlingDiscoMailWin:initUI(params)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self.m_machine = params.machine
    local resourceFilename = "xxxx/xxxx.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true
end
function DazzlingDiscoMailWin:setFunc(_func)
    self.m_func = _func
end
function DazzlingDiscoMailWin:initViewData(coins)
    self:runCsbAction("start",false,function()
        self.m_click = false
        self:runCsbAction("idle", true, nil, 60)
    end,60)

    local m_lb_coins = self:findChild("m_lb_coins")
    m_lb_coins:setString(util_formatCoins(self.m_winCoins, 50))
    self:updateLabelSize({label = m_lb_coins, sx = 1, sy = 1}, 692)
end

function DazzlingDiscoMailWin:onEnter()
    DazzlingDiscoMailWin.super.onEnter(self)
end

function DazzlingDiscoMailWin:onExit()
    DazzlingDiscoMailWin.super.onExit(self)
    
end

function DazzlingDiscoMailWin:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        self:sendCollectMail()
    end
end

function DazzlingDiscoMailWin:closeUI()
    self:runCsbAction("over",false,function()
        if self.m_func then
            self.m_func()
        end
        self:removeFromParent()
    end,60)
end


function DazzlingDiscoMailWin:sendCollectMail()
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

function DazzlingDiscoMailWin:changeSuccess()
    self:closeUI()
end

function DazzlingDiscoMailWin:changeFailed()
end

return DazzlingDiscoMailWin
