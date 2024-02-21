local baseView = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_DailyBonusNode = class("LobbyBottom_DailyBonusNode", baseView)

function LobbyBottom_DailyBonusNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomDailyBonusNode.csb")
    self:initView()
    self:updateView()
    self:updateDailyBonus()
    schedule(self, util_node_handler(self, self.updateDailyBonus), 1)
end

function LobbyBottom_DailyBonusNode:initView()
    self.m_lock = self:findChild("lock")
    self.m_tips_msg = self:findChild("tipsNode")
    self.m_unlockValue = self:findChild("unlockValue")
    self.m_spRedPoint = self:findChild("spRedPoint") -- 红点的底
    self.btnFunc = self:findChild("Button_1")
    self.m_sp_new = self:findChild("sp_new")
    self.m_lockIocn = self:findChild("lockIcon")
    self.m_tipsNode_downloading = self:findChild("tipsNode_downloading")
    if self.btnFunc then
        self.btnFunc:setSwallowTouches(false)
    end
end

function LobbyBottom_DailyBonusNode:updateView()
    self.m_lockIocn:setVisible(false)
    self.m_lock:setVisible(false)
    self.m_sp_new:setVisible(false)
    self.m_spRedPoint:setVisible(false)
    self.m_tipsNode_downloading:setVisible(false)
    self.m_tips_msg:setVisible(false)
end

function LobbyBottom_DailyBonusNode:getDailyBonusOpenLv()
    local openLevel = globalData.constantData.DAILYBOUNS_OPEN_LEVEL or 20 --解锁等级
    local noviceSwitch = globalData.constantData.NOVICE_NEWUSER_SIGNIN_SWITCH -- 新手期签到开关
    local noviceOpenLevel = globalData.constantData.NOVICE_CHECK_OPEN_LEVEL --新手期开启等级
    local noviceOpenLevelV2 = globalData.constantData.NOVICE_CHECK_V2_OPEN_LEVEL --新手期开启等级V2
    local curLevel = globalData.userRunData.levelNum --玩家等级

    local dailySignData = globalData.dailySignData --签到数据
    local Days = dailySignData:getDays()
    local dailyBonusNoviceData = globalData.dailyBonusNoviceData --新手期签到数据
    local isHasData = dailyBonusNoviceData:isHasData()
    if noviceSwitch and noviceSwitch > 0 then -- 新手期签到开关，0-关，1-开
        if noviceOpenLevel and noviceOpenLevel > 0 then
            if isHasData or curLevel < noviceOpenLevel then
                openLevel = noviceOpenLevel
            end
        end

        -- 新手期签到B组
        local mgr = G_GetMgr(G_REF.NoviceSevenSign)
        if mgr and globalData.GameConfig:checkABtestGroup("NoviceCheck", "B") and noviceOpenLevelV2 then
            openLevel = noviceOpenLevelV2
            if curLevel >= openLevel and (not mgr:isRunning()) then
                --新手期签到结束了 切换到普通签到
                openLevel = globalData.constantData.DAILYBOUNS_OPEN_LEVEL or 20 --解锁等级
            end
        end
    end

    return openLevel
end

function LobbyBottom_DailyBonusNode:updateDailyBonus()
    local openLevel = self:getDailyBonusOpenLv()
    self.m_unlockValue:setString(openLevel)
    self.m_openLevel = openLevel

    local dailySignData = globalData.dailySignData --签到数据
    local Days = dailySignData:getDays()
    local dailyBonusNoviceData = globalData.dailyBonusNoviceData --新手期签到数据
    local isHasData = dailyBonusNoviceData:isHasData()
    if Days or isHasData then
        if globalData.userRunData.levelNum >= openLevel then
            self.m_lock:setVisible(false)
            self.m_LockState = false
        else
            self.m_lock:setVisible(true)
            self.m_LockState = true
        end
    else
        local bLock = globalData.userRunData.levelNum < openLevel
        self.m_lock:setVisible(bLock)
        self.m_LockState = bLock
    end
end

-- 节点处理逻辑 --
function LobbyBottom_DailyBonusNode:clickFunc()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    self:updateDailyBonus() -- 新手期签到结束 等级 没达到普通签到 为 锁定状态
    if self.m_LockState then
        self:showTips()
        return
    end

    local mgr = G_GetMgr(G_REF.NoviceSevenSign)
    if mgr and mgr:isRunning() then
        mgr:showMainLayer()
    elseif globalData.dailyBonusNoviceData and globalData.dailyBonusNoviceData:isHasData() then
        local dailyBonusNoviceMgr = require("manager.DailyBonusNoviceMgr")
        if dailyBonusNoviceMgr then
            dailyBonusNoviceMgr:getInstance():showMainLayer()
        end
    else
        local dailyBonusMgr = require("manager.DailySignBonusManager")
        if dailyBonusMgr then
            dailyBonusMgr:getInstance():showMainLayer()
        end
    end
    self:openLayerSuccess()
end
-- 开启等级提示
function LobbyBottom_DailyBonusNode:showTips(_tips)
    if _tips == nil then
        _tips = self.m_tips_msg
    end
    if _tips:isVisible() then
        _tips:setVisible(false)
        return
    end
    _tips:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        _tips,
        function()
            performWithDelay(
                self,
                function()
                    if not tolua.isnull(_tips) then
                        _tips:setVisible(false)
                    end
                end,
                0.1
            )
        end
    )
end

return LobbyBottom_DailyBonusNode
