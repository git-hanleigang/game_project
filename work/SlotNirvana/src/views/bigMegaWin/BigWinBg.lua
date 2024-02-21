local BigWinLayer = class("BigWinLayer", BaseLayer)

--四种赢钱的音效
local SoundStartEnum = {
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_START1,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_START2,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_START3,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_START4
}
local SoundOverEnum = {
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER1,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER2,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER3,
    SOUND_ENUM.MUSIC_COMMON_BIGWIN_OVER4
}

local SpineResName = {
    [1] = {"bigwin/bigwin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "xzg", "bigwin/bigwin", "xx2", "xx"},
    [2] = {"megawin/megawin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "xzg", "megawin/megawin", "xx2", "xx"},
    [3] = {"epicwin/epicwin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "xzg", "epicwin/epicwin", "xx2", "xx"},
    [4] = {"legendarywin/legendarywin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "xzg", "legendarywin/legendarywin", "xx2", "xx"},
}
local SpineResName_withPet = {
    [1] = {"bigwin/bigwin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "b11", "b12", "b13", "xzg", "bigwin/bigwin", "xx2", "xx"},
    [2] = {"megawin/megawin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "b11", "b12", "b13", "xzg", "megawin/megawin", "xx2", "xx"},
    [3] = {"epicwin/epicwin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "b11", "b12", "b13", "xzg", "epicwin/epicwin", "xx2", "xx"},
    [4] = {"legendarywin/legendarywin_di", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "b10", "b11", "b12", "b13", "xzg", "legendarywin/legendarywin", "xx2", "xx"},
}

function BigWinLayer:initDatas(_winType)
    BigWinLayer.super.initDatas(self)

    self.m_winType = _winType or 1
    self.m_bCanIsTouch = false
    self.m_spineList = {} -- spine 列表
    self.m_petSpinAddCoins = G_GetMgr(G_REF.Sidekicks):getSpinWinCoins()
    self:setShownAsPortrait(globalData.slotRunData:isFramePortrait())
    self:setLandscapeCsbName("CommonWin/csd/BigWinSpineLayer.csb")
    self:setPortraitCsbName("CommonWin/csd/BigWinSpineLayer_Portrait.csb")
end

function BigWinLayer:initViewData(_nWinNum, _winType, _callback)
    --目前只有bigwin
    self.m_winNum = _nWinNum or 0
    self.m_winType = _winType or 1
    self.m_callback = _callback or function() end
end

function BigWinLayer:initCsbNodes()
    BigWinLayer.super.initCsbNodes(self)
    
    self.m_spineRef = self:findChild("node_spine")
    -- if CC_RESOLUTION_RATIO == 2 and not self:isPortraitScreen() then
    if self:isShownAsPortrait() then
        if self.m_winType == 4 then
            self.m_spineRef:setScale(0.95)
        else
            -- self.m_spineRef:setScale(0.8)
        end
    end
end

function BigWinLayer:initView()
    BigWinLayer.super.initView(self)
    self.m_lb_pet_bonus = self:findChild("lb_pet_bonus")
    self.m_lb_pet_bonus:setVisible(false)

    -- 添加 spine
    self:addSpineUI()
end

-- 添加 spine
function BigWinLayer:addSpineUI()
    local spineResList = SpineResName[self.m_winType]
    if self.m_petSpinAddCoins > toLongNumber(0) then
        spineResList = SpineResName_withPet[self.m_winType]
        self:setSpecialBonus()
    end

    if type(spineResList) ~= "table" then
        return
    end

    for i=1, #spineResList do
        local resPath = "CommonWin/spine/" .. spineResList[i]
        local spine = util_spineCreate(resPath, true, true, 1)
        if spineResList[i] == "xx2" then
            self.m_spineCoins = spine
            util_spinePushBindNode(spine, "node_bfb", self.m_lb_pet_bonus)
        end
        -- 竖版金币框缩放0.64，其他的缩放0.68 (bigWin和meagWin主体大点)
        if self:isShownAsPortrait() then
            local scale = spineResList[i] == "xx2" and 0.64 or (self.m_winType~=3 and 0.8 or 0.68)
            spine:setScale(scale)
        end 
        self.m_spineRef:addChild(spine)
        table.insert(self.m_spineList, spine)
    end
end

-- 播放spine动画
function BigWinLayer:playSpineAct()
    for _, _spine in pairs(self.m_spineList) do
        util_spinePlay(_spine, "animation")
    end
end

-- 添加金币
function BigWinLayer:addCoinsLableUI()
    if not self.m_spineCoins then
        return
    end
    local lbView = util_createView("views.bigMegaWin.BigWinCoinsUI", self.m_winNum, self.m_petSpinAddCoins, self)
    util_spinePushBindNode(self.m_spineCoins, "coinscount", lbView)
    self.m_lbCoinsUI = lbView
end

function BigWinLayer:setSpecialBonus()
    local bonus = G_GetMgr(G_REF.Sidekicks):getPetSpecialBonus(1)
    self.m_lb_pet_bonus:setString(string.format("+%s%%", bonus*100))
    self.m_lb_pet_bonus:setVisible(true)
end

-- 宠物加成动画
function BigWinLayer:playPetSkillAddAct()
    if tolua.isnull(self) then
        return
    end
    local petBigWinSpinName = G_GetMgr(G_REF.Sidekicks):getBigWinSpinName()
    local spineList = {petBigWinSpinName, "Sidekicks_ef"}

    if self.m_spineCoins then
        util_spinePlay(self.m_spineCoins, "animation2")
        self.m_lbCoinsUI:playPetCoinScaleAct()
    end

    local bRegisterOverCb = false
    for i=1, #spineList do
        local name = spineList[i]
        local resPath = "CommonWin/spine/sidekicks/" .. name
        if util_IsFileExist(resPath .. ".atlas") then
            local seasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
            local sound = string.format("Sidekicks_%s/sound/Sideicks_bigWinBonus.mp3", seasonIdx)
            gLobalSoundManager:playSound(sound)

            local spine = util_spineCreate(resPath, true, true, 1)
            self.m_spineRef:addChild(spine)
            util_spinePlay(spine, "animation")
            if not bRegisterOverCb then
                bRegisterOverCb = true
                performWithDelay(self, function()
                    if tolua.isnull(self.m_lbCoinsUI) then
                        self:closeUI()
                    else
                        self.m_lbCoinsUI:playPetAddWinCoinsAct()
                    end
                end, 42 / 30)
            end
        end
    end
    if bRegisterOverCb then
        return
    end
    self:closeUI()
end

function BigWinLayer:closeUI()
    -- if self.m_bClosed then
    --     return
    -- end
    -- self.m_bClosed = true
    BigWinLayer.super.closeUI(self, self.m_callback)
end

function BigWinLayer:onEnter()
    BigWinLayer.super.onEnter(self)
    -- 音效
    self:playSounds()
end

-- 播放音效
function BigWinLayer:playSounds()
    gLobalSoundManager:pauseBgMusic()
    if SoundStartEnum[self.m_winType] then
        self.m_bigwinAudioId = gLobalSoundManager:playSound(SoundStartEnum[self.m_winType])
    end
end

-- 停止音效 恢复背景音
function BigWinLayer:stopSounds()
    gLobalSoundManager:resumeBgMusic( )
    if self.m_bigwinAudioId then
        gLobalSoundManager:stopAudio(self.m_bigwinAudioId)
    end
end

-- 弹出动画
function BigWinLayer:playShowAction()
    local userDefAction = function(_cb)
        self:runCsbAction("in", false, _cb, 60)
        self:playSpineAct()
    end
    BigWinLayer.super.playShowAction(self, userDefAction)
end

-- 弹出动画结束会掉
function BigWinLayer:showActionCallback()
    BigWinLayer.super.showActionCallback(self)

    self:runCsbAction("idle", true)
    performWithDelay(self, function()
        -- 添加金币
        self:addCoinsLableUI()
        self.m_bCanIsTouch = true
    end, 0.7)
end

-- 播放隐藏动画 重写
function BigWinLayer:playHideAction()

    -- 延迟隐藏背景蒙版
    self:setMaskHideDelay(15 / 60)

    local userDefAction = function(_cb)
        local scale = self.m_spineRef:getScaleX()
        local actionList = {}
        actionList[#actionList + 1] = cc.EaseSineOut:create(cc.ScaleTo:create(4 / 60, scale * 1.02))
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self:addOverSpineUI(_cb)
        end)

        local act1 = cc.EaseSineIn:create(cc.ScaleTo:create(16 / 60, scale * 0.3, 0))
        local act2 = cc.FadeTo:create(16 / 60, 0)
        actionList[#actionList + 1] = cc.Spawn:create(act1, act2)
        
        actionList[#actionList + 1] = cc.DelayTime:create(14 / 60)
        actionList[#actionList + 1] = cc.CallFunc:create(_cb)
        local seq = cc.Sequence:create(actionList)
        self.m_spineRef:runAction(seq)
    end
    BigWinLayer.super.playHideAction(self, userDefAction)

    -- userDefAction(function()
    --     self:hideActionCallback()
    --     if not tolua.isnull(self) then
    --         self:removeFromParent()
    --     end
    -- end)
    -- -- 延迟隐藏蒙版
    -- performWithDelay(self, function()
    --     self:maskHide(15 / 60)
    -- end, 16/60)
end

function BigWinLayer:addOverSpineUI()
    local spine = util_spineCreate("CommonWin/spine/over", true, true, 1)
    self:addChild(spine)
    spine:move(self.m_spineRef:getPositionX(), self.m_spineRef:getPositionY())
    spine:setScale(self.m_spineRef:getScale())
    if self.m_petSpinAddCoins > toLongNumber(0) then
        util_spinePlay(spine, "animation2")
    else
        util_spinePlay(spine, "animation")
    end
end

-- 背景遮罩触摸
function BigWinLayer:onClickMask()
    if self.m_bCloseing or not self.m_bCanIsTouch or tolua.isnull(self.m_lbCoinsUI) then
        return
    end

    self.m_lbCoinsUI:interruptCoinAddJumpAct()
    self.m_bCloseing = true
    -- 被打断时需要播放结束音效 -- 静默
    if self.m_bigwinAudioId then
        gLobalSoundManager:muteAudioById(self.m_bigwinAudioId)
    end
    if SoundOverEnum[self.m_winType] then
        gLobalSoundManager:playSound(SoundOverEnum[self.m_winType])
    end
end

function BigWinLayer:clickFunc(sender)
    self:onClickMask()
end

-- 系统返回键调用
function BigWinLayer:onKeyBack()
    if self.m_bCloseing or not self.m_bCanIsTouch or tolua.isnull(self.m_lbCoinsUI) then
        return
    end

    self.m_lbCoinsUI:interruptCoinAddJumpAct()
    self.m_bCloseing = true
end

-- 注册事件
function BigWinLayer:registerListener()
    BigWinLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self,
    function(target,data)
        gLobalSoundManager:pauseBgMusic()
    end,ViewEventType.NOTIFY_PLAYBGMUSIC)

    gLobalNoticManager:addObserver(self,
    function(target,data)
        gLobalSoundManager:pauseBgMusic()
    end,ViewEventType.NOTIFY_SETBGMUSICVOLUME)
end

function BigWinLayer:onExit()
    -- 停止音效 恢复背景音
    self:stopSounds()
    -- 插屏广告处理
    self:dealAdsLogic()
    -- 推送通知开关
    self:dealNotificationLogic()

    BigWinLayer.super.onExit(self)
end

-- 插屏广告处理
function BigWinLayer:dealAdsLogic()
    local bigWinNoAdLevel = function (  )
        -- 这些关卡不能弹bigwin 广告
        local result = not not globalData.slotRunData.m_canPlayBigWinAdvertising
        if globalData.slotRunData.gameModuleName == "GirlsMagic" then
            result = false
        end
        return result
    end
    -- 播放插屏广告
    -- csc 2021-12-07 FREE SPIN过程中的大赢不触发插屏
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.BigMegaWinClose) and bigWinNoAdLevel() then
            gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.BigMegaWinClose)
            gLobalAdsControl:playAutoAds(PushViewPosType.BigMegaWinClose)
        end
    end
end

function BigWinLayer:requestNotification()
    if not util_isSupportVersion("1.5.9") then
        return
    end 
    if globalData.userRunData.levelNum >= 10 and not gLobalDataManager:getBoolByField("requestNotificationStatus", false) then 
        gLobalDataManager:setBoolByField("requestNotificationStatus", true)
        globalPlatformManager:requestNotificationStatus()
    end
end

-- 推送通知开关
function BigWinLayer:dealNotificationLogic()
    -- csc 2021-08-26 检测当前是否要推送玩家打开通知
    if device.platform == "ios" or device.platform == "mac" then
        self:requestNotification() 

        -- csc 2021-11-19 15:15:08 新增att 弹板
        if not util_isSupportVersion("1.8.7", "ios") and gLobalAdsControl:getCheckATTFlag("bigwin", "1.5.9") then -- 如果当前有att 请求 并且等级 = 2
            release_print("----csc bigwin check att ")
            gLobalAdsControl:createATTLayer("bigwin")
        end
    end
end

return BigWinLayer
