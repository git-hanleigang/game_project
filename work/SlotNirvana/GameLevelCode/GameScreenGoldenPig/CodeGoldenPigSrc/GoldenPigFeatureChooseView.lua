---
--smy
--2018年5月24日
--GoldenPigFeatureChooseView.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local SendDataManager = require "network.SendDataManager"
local GoldenPigFeatureChooseView = class("GoldenPigFeatureChooseView",util_require("base.BaseView"))
GoldenPigFeatureChooseView.m_choseFsCallFun = nil
GoldenPigFeatureChooseView.m_choseRespinCallFun = nil
GoldenPigFeatureChooseView.m_dropPig = nil

function GoldenPigFeatureChooseView:initUI()
    self.m_featureChooseIdx = 0
    self.m_schDelay1 = false

    self:createCsbNode("GoldenPig/GameScreenGoldenPigChoose.csb")
    local respin = self:findChild("btnRespin")
    self:addClick(respin)
    local freespin = self:findChild("btnFreespin")
    self:addClick(freespin)

    -- local pig = util_spineCreateDifferentPath("GoldenPig_BonusBG_0", "goldpig_bg", true, true)
    local pig = util_spineCreate("GoldenPig_BonusBG_0", true, true)
    util_spinePlay(pig, "idleframe", true)
    pig:setScale(0.5)
    self:findChild("pigNode"):addChild(pig)
    pig:setPositionY(-10)

    -- self.m_dropPig = util_spineCreateDifferentPath("GoldenPig_BonusBG_0", "goldpig_bg", true, true)
    self.m_dropPig = util_spineCreate("GoldenPig_BonusBG_0", true, true)
    util_spinePlay(self.m_dropPig, "buling", false)
    self.m_dropPig:setScale(1.2)
    self:findChild("root"):addChild(self.m_dropPig)
    self.m_dropPig:setPosition(cc.p(0, 600))
    -- local labFreeSpin = self:findChild("free_spin_times")

    -- local labRespin = self:findChild("respin_times")
    
    --  z展示动画定义
    self.runCsbActionLock = "over1"
    self.runCsbActionfreespin = "over2"

end

function GoldenPigFeatureChooseView:onEnter()
    self:runCsbAction("start", false, function()
        if self.m_schDelay1 == false then
            self:runCsbAction("idle", true)
        end
    end)

    gLobalSoundManager:stopBgMusic()
    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_show_choose_layer.mp3") 
    
end

function GoldenPigFeatureChooseView:onExit(  )

end

function GoldenPigFeatureChooseView:setChoseCallFun(choseFs, choseRespin)
    self.m_choseFsCallFun = choseFs
    self.m_choseRespinCallFun = choseRespin
end
function GoldenPigFeatureChooseView:clickFunc(sender)

    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_choose.mp3") 
    self.m_schDelay1 = true
    local name = sender:getName()
    local tag = sender:getTag()    
    self:clickButton_CallFun(name)
end
function GoldenPigFeatureChooseView:clickButton_CallFun(name)
    local tag=0
    if name == "btnRespin" then
        tag=1
    else
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
    end
    self.m_featureChooseIdx = tag
    
    self.m_csbOwner["btnFreespin"]:setEnabled(false)
    self.m_csbOwner["btnRespin"]:setEnabled(false)
    self:choseOver( )
    
     
    local seq = cc.Sequence:create(cc.DelayTime:create(0.8), cc.CallFunc:create(function()
        gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_drop.mp3")
    end), cc.EaseBackOut:create(cc.MoveTo:create(0.6,cc.p(0, -40))), cc.CallFunc:create(function ()
        util_spinePlay(self.m_dropPig, "buling", false)
        util_spineEndCallFunc(self.m_dropPig, "buling", function()
            gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pig_break.mp3")
            util_spinePlay(self.m_dropPig, "over", false)
        end)
    end))
    self.m_dropPig:runAction(seq)
    
    -- scheduler.unschedulesByTargetName("LinkCat_GoldenPigFeatureChooseView")
end

function GoldenPigFeatureChooseView:choseOver( )
    self:initGameOver()
end

--进入游戏初始化游戏数据 判断新游戏还是断线重连 子类调用
function GoldenPigFeatureChooseView:initViewData(freeSpinNum, respinNum, func)
    self.m_nFreeSpinNum = freeSpinNum
    self.m_csbOwner["free_spin_times"]:setString(freeSpinNum)
    self.m_csbOwner["respin_times"]:setString(respinNum)
    self.m_callFunc = func
end

--初始化游戏结束状态 子类调用
function GoldenPigFeatureChooseView:initGameOver()
    
    if self.m_featureChooseIdx == 1 then
        self:runCsbAction(self.runCsbActionLock) 
    else
        self:runCsbAction(self.runCsbActionfreespin)
    end

    -- self:sendData(self.m_featureChooseIdx)
    if self.m_featureChooseIdx == 1 then
        gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_choose_fs.mp3")
    else
        gLobalSoundManager:playSound("LinkCatSounds/music_linkCat_choose_reward.mp3") 
    end

    scheduler.performWithDelayGlobal(function()

        if self.m_callFunc then
            self.m_callFunc(self.m_featureChooseIdx)
        end
        self:removeFromParent()
    end, 6, "GoldenPigFeatureChooseView")   
end

function GoldenPigFeatureChooseView:sendData(index)
    if self.m_isLocalData then
        -- scheduler.performWithDelayGlobal(function()
        --     self:recvBaseData(self:getLoaclData())
        -- end, 0.5,"BaseGameNew")
    else
        local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
        local httpSendMgr = SendDataManager:getInstance()
        httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
    end
end

return GoldenPigFeatureChooseView