---
local MiningManiaMailWin = class("MiningManiaMailWin", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

function MiningManiaMailWin:initUI(params)
    local isAutoScale = false
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self.m_machine = params.machine
    self.m_index = params.index
    local resourceFilename = "MiningMania/MinecartRushOver.csb"
    self:createCsbNode(resourceFilename, isAutoScale)
    self.m_click = true

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end
function MiningManiaMailWin:setFunc(_func)
    self.m_func = _func
end
function MiningManiaMailWin:initViewData(coins, _userMul, _userScore)
    self.m_endCoins = coins
    if _userMul then
        globalMachineController:playBgmAndResume(PublicConfig.Music_BonusCar_EndReward_Start, 3, 0, 1)
        self:runCsbAction("start",false,function()
            performWithDelay(self.m_scWaitNode, function()
                self:jumpCoins(coins)
            end, 54/60)
            gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_DialogMul)
            self:runCsbAction("actionframe", false, function()
                self.m_click = false
                self:runCsbAction("idle", true, nil, 60)
            end)
        end,60)
        local m_lb_mul = self:findChild("m_lb_num")
        m_lb_mul:setString("X".._userMul)
        self:setEndCoins(_userScore)
    else
        self:runCsbAction("start",false,function()
            self.m_click = false
            self:runCsbAction("idle", true, nil, 60)
        end,60)
        self:setEndCoins(coins)
    end
end

--跳钱
function MiningManiaMailWin:jumpCoins(_targetCoins)
    -- 每秒60帧
    local coinRiseNum =  _targetCoins / (4 * 60)  
    local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    --  数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Coins)

    self.m_updateAction = schedule(self,function()
        curCoins = curCoins + coinRiseNum
        curCoins = curCoins < _targetCoins and curCoins or _targetCoins

        self:setEndCoins(curCoins)
        if curCoins >= _targetCoins then
            self:stopUpDateCoins()
        end
    end,0.008)
end

function MiningManiaMailWin:stopUpDateCoins()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
        gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Jump_Stop)
    end
end

function MiningManiaMailWin:setEndCoins(coins)
    local m_lb_coins = self:findChild("m_lb_coins")
    m_lb_coins:setString(util_formatCoins(coins, 50))
    self:updateLabelSize({label = m_lb_coins, sx = 1, sy = 1}, 591)
end

function MiningManiaMailWin:onEnter()
    MiningManiaMailWin.super.onEnter(self)
end

function MiningManiaMailWin:onExit()
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    if self.m_updateAction then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
    MiningManiaMailWin.super.onExit(self)
end

function MiningManiaMailWin:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return
        end
        self:clickCollectBtn()
    end
end

function MiningManiaMailWin:clickCollectBtn()
    if self.m_updateAction ~= nil then
        self:stopUpDateCoins()
        self:setEndCoins(self.m_endCoins)
    else
        self.m_click = true
        self:sendCollectMail()
    end
end

function MiningManiaMailWin:closeUI()
    gLobalSoundManager:playSound(PublicConfig.Music_Normal_Click)
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_EndReward_Over)
    end, 5/60)
    self:runCsbAction("over",false,function()
        if self.m_func then
            self.m_func()
            self.m_func = nil
        end
        self:removeFromParent()
    end,60)
end

function MiningManiaMailWin:sendCollectMail()
    local gameName = self.m_machine:getNetWorkModuleName()
    --参数传-1位领取所有奖励,领取当前奖励传数组最后一位索引
    gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,self.m_index,function(data)
        if not tolua.isnull(self) then
            self:changeSuccess()
        end
    end,function(errorCode, errorData)
        if not tolua.isnull(self) then
            self:changeFailed()
        end
    end)
end

function MiningManiaMailWin:changeSuccess()
    self:closeUI()
end

function MiningManiaMailWin:changeFailed()
    self:closeUI()
end

return MiningManiaMailWin
