---
--island
--2018年4月12日
--MiningManiaBonusCarGotReward.lua
local MiningManiaBonusCarGotReward = class("MiningManiaBonusCarGotReward", util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

function MiningManiaBonusCarGotReward:onEnter()
    MiningManiaBonusCarGotReward.super.onEnter(self)
end
function MiningManiaBonusCarGotReward:onExit()
    MiningManiaBonusCarGotReward.super.onExit(self)
end

function MiningManiaBonusCarGotReward:initUI(_index)
    self.m_index = _index
    if _index == 1 then
        self:createCsbNode("MiningMania/YouGot.csb")
    else
        self:createCsbNode("MiningMania/YouGot_0.csb")
    end

    local lightAni = util_createAnimation("MiningMania_tanban_guang.csb")
    self:findChild("guang"):addChild(lightAni)
    lightAni:runCsbAction("actionframe", true)
    
    self.m_rewardText = self:findChild("m_lb_num")
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 弹板入口 刷新
function MiningManiaBonusCarGotReward:initViewData(_data)
    local rewardMul = _data.p_mul
    self.m_endCallFunc = _data.p_callFunc
    self:setReward(rewardMul)

    local randomNum = math.random(1, 2)
    if self.m_index == 1 then
        local soundEffect = PublicConfig.Music_BonusCar_Collect_Mul[randomNum]
        gLobalSoundManager:playSound(soundEffect)
    else
        local soundEffect = PublicConfig.Music_BonusCar_Collect_Time[randomNum]
        gLobalSoundManager:playSound(soundEffect)
    end

    self.m_allowClick = false
    self:runCsbAction("start", false, function()
        self.m_allowClick = true
        self:runCsbAction("idle", true)
    end)
    performWithDelay(self, function()
        self:hideSelf()
    end, 2.0)
end

function MiningManiaBonusCarGotReward:setReward(_rewardMul)
    if self.m_index == 1 then
        self.m_rewardText:setString("X".._rewardMul)
    else
        self.m_rewardText:setString(_rewardMul.."S")
    end
end

function MiningManiaBonusCarGotReward:hideSelf()
    self:runCsbAction("over", false, function()
        if type(self.m_endCallFunc) == "function" then
            self.m_endCallFunc()
            self.m_endCallFunc = nil
        end
    end)
    
end

return MiningManiaBonusCarGotReward

