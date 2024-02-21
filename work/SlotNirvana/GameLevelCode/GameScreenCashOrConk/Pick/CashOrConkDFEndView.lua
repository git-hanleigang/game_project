local CashOrConkDFEndView = class("CashOrConkDFEndView", util_require("base.BaseView"))
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

CashOrConkDFEndView.m_isJumpOver = false


function CashOrConkDFEndView:initUI(data)
    local state = data and data.state
    local over4 = data and data.over4 or 2
    self.m_coins = data.coins
    self.m_click = false
    local resourceFilename = "CashOrConk/CashOrConk_DF1_Over.csb"
    self:createCsbNode(resourceFilename)

    self._lb_coin = self:findChild("m_lb_coins")
    -- “Node_guang”挂Socre_CashOrConk_tb_guang.csd播idleframe（0，2000）
    -- “juese_tb”挂Socre_CashOrConk_juese播tb_idle2（0，120）
    -- “Node_sg”挂CashOrConk_tb_sg播sg_idle（0，120）
    -- "Node_zi_sg"挂 CashOrConk_tb_sg播sg_zi_idle1（0，120）

    local spine = util_spineCreate("Socre_CashOrConk_juese",true,true)
    self:findChild("juese_tb"):addChild(spine)
    util_spinePlayAction(spine, "tb_idle2", true)
    local effs = {
        {csb = "Socre_CashOrConk_tb_guang.csb",
        node = "Node_guang",anim = "idleframe"},
        {csb = "Socre_CashOrConk_juese.csb",
        node = "juese_tb",anim = "tb_idle2"},
        {csb = "CashOrConk_tb_sg.csb",
        node = "Node_sg",anim = "sg_idle"},
        {csb = "CashOrConk_tb_sg.csb",
        node = "Node_zi_sg",anim = "sg_zi_idle1"},
    }

    for i,v in ipairs(effs) do
        local anim = util_createAnimation(v.csb)
        self:findChild(v.node):addChild(anim)
        anim:playAction(v.anim)
    end

    local node_state = {
        {
            node = "CashOrConk/CashOrConk_DF2_Over.csb",root = "Node_DF2_Over",
        },
        {
            node = "CashOrConk/CashOrConk_DF3_Over.csb",root = "Node_DF3_Over",
        },
        {
            node = "CashOrConk/CashOrConk_Sanxuanyi_Over1.csb",root = "Node_Sanxuanyi_Over1",
        },
        {
            node = "CashOrConk/CashOrConk_Sanxuanyi_Over3.csb",root = "Node_Sanxuanyi_Over2",
        },
        {
            node = "CashOrConk/CashOrConk_Sanxuanyi_Over3.csb",root = "Node_Sanxuanyi_Over3",
        },
    }

    for i,v in ipairs(node_state) do
        local anim = util_createAnimation(v.node)
        self:findChild(v.root):addChild(anim)
    end

    local status1 = tonumber(string.split(state,"_")[1])
    if status1 < 4 then
        for i=1,3 do
            self:findChild("Node_DF"..i.."_Over"):setVisible(i == status1)
        end
        for i=1,3 do
            self:findChild("Node_Sanxuanyi_Over"..i):setVisible(false)
        end
    elseif status1 == 4 then
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_18)
        for i=1,3 do
            self:findChild("Node_Sanxuanyi_Over"..i):setVisible(i == over4)
        end
        for i=1,3 do
            self:findChild("Node_DF"..i.."_Over"):setVisible(false)
        end
    end
end

function CashOrConkDFEndView:popView()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_14)
    --数字上涨音效
    -- local key = string.format("sound_jackpotWinView_%d", index)
    -- self.m_bgSoundId =  gLobalSoundManager:playSound(SoundConfig[key])
    self:setWinCoinsLab(0)
    self:jumpCoins(nil, 0)
    self:runCsbAction("start",false,function(  )
        self.m_click = true
        self:runCsbAction("idle",true)
        if self._idleAniRunFunc then
            self._idleAniRunFunc()
        end
    end)
end


function CashOrConkDFEndView:setWinCoinsLab(_coins)
    local labCoins = self._lb_coin
    labCoins:setString(util_formatCoins(_coins, 50))
    self:updateLabelSize({label=labCoins,sx=0.93,sy=0.93}, 790)
end

function CashOrConkDFEndView:onEnter()
    CashOrConkDFEndView.super.onEnter(self)
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

function CashOrConkDFEndView:onExit()
    CashOrConkDFEndView.super.onExit(self)
    if not self.m_isJumpOver then
        self:stopUpDateCoins()
    end

    if self.m_bgSoundId then
        gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
end

function CashOrConkDFEndView:clickFunc(sender)
    if not self.m_click then
        return 
    end
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_COC_baseLineFrame_click)
    local name = sender:getName()
    if name == "Button_1" then
        -- gLobalSoundManager:playSound(LeoWealthPublicConfig.sound_LeoWealth_49)
        if not self.m_isJumpOver then
            self:stopUpDateCoins()
            self:setWinCoinsLab(self.m_coins)
        else
            self:playOverAnim()
        end
    end
end

function CashOrConkDFEndView:jumpCoins(coins, startCoins)
    --数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_dfendviewlbroll,true)
    if not startCoins then
        startCoins = 0
    end
    local node = self._lb_coin
    node:setString(startCoins)
    local addValue = (self.m_coins - startCoins) / (60 * 5)
    util_jumpNum(node,startCoins,self.m_coins,addValue,1/60,{30}, nil, nil,function(  )
        self:stopUpDateCoins()
    end,function()
        self:updateLabelSize({label=node,sx=0.93,sy=0.93}, 790)
    end)
end

function CashOrConkDFEndView:stopUpDateCoins()
    self.m_isJumpOver = true
    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    local node = self._lb_coin
    node:unscheduleUpdate()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_dfendviewlbrollstop)  --结束音效
end

function CashOrConkDFEndView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function CashOrConkDFEndView:setIdleAniRunFunc(func)
    self._idleAniRunFunc = func
end

function CashOrConkDFEndView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

function CashOrConkDFEndView:playOverAnim()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_12)
    self:findChild("Button_1"):setTouchEnabled(false)
    self.m_click = false

    self:stopAllActions()
    gLobalNoticManager:postNotification("HIDEEFFECT_SUPERHERO")
    -- gLobalSoundManager:playSound(LeoWealthPublicConfig.sound_LeoWealth_40) --界面关闭音效
    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    self:runCsbAction("over", false)
    local overTime = util_csbGetAnimTimes(self.m_csbAct, "over")
    performWithDelay(self,function()
        if self.m_overRuncallfunc then
            self.m_overRuncallfunc()
            self.m_overRuncallfunc = nil
        end

        self:removeFromParent()
    end,overTime)
end

return CashOrConkDFEndView