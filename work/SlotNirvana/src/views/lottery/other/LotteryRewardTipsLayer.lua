--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-01-21 19:30:42
    describe:未中奖弹框
]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryRewardTipsLayer = class("LotteryRewardTipsLayer", BaseLayer)

function LotteryRewardTipsLayer:ctor()
    LotteryRewardTipsLayer.super.ctor(self)
    self:setPauseSlotsEnabled(true)

    self:setExtendData("LotteryRewardTipsLayer")
    self:setLandscapeCsbName("Lottery/csd/Drawlottery/Lottery_Drawlottery_rewards_nowin.csb")
end


function LotteryRewardTipsLayer:initView()
 
    --spine
    -- local parent = self:findChild("spine")
    -- local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true)
    -- parent:addChild(spineNode)
    -- util_spinePlay(spineNode, "idle2", true)
end

function LotteryRewardTipsLayer:initSpineUI()
    LotteryRewardTipsLayer.super.initSpineUI(self)

    --spine
    local parent = self:findChild("spine")
    local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true, 1)
    parent:addChild(spineNode)
    util_spinePlay(spineNode, "idle2", true)
end

function LotteryRewardTipsLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_OK" then
        sender:setTouchEnabled(false)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.Lottery):sendCollectReward()
        self:closeUI()
    end
end

function LotteryRewardTipsLayer:onShowedCallFunc()
    LotteryRewardTipsLayer.super.onShowedCallFunc(self)
    gLobalSoundManager:playSound("Lottery/sounds/Lottery_pop_collect_reward_layer.mp3")
    self:runCsbAction("idle", true)
end

function LotteryRewardTipsLayer:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end


    LotteryRewardTipsLayer.super.closeUI(self,callFunc)
end

return LotteryRewardTipsLayer
