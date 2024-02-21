---
--smy
--2018年4月18日
--GhostCaptainWheelView.lua
local PublicConfig = require "GhostCaptainPublicConfig"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local GhostCaptainWheelView = class("GhostCaptainWheelView", BaseGame)
GhostCaptainWheelView.m_curShowWheelType = 1 --当前显示转盘类型 1普通 2super

local MAX_WHEEL_COUNT   =   12  -- 转盘区域数
local ITEM_BG = {
        mini = "green",
        minor = "blue",
        major = "purple",
        grand = "red",
        free1 = "orange",
        free2 = "orange",
        m1 = "cyan",
        m2 = "cyan",
        m3 = "cyan",
        m4 = "cyan",
    }
local ALL_ITEM_BG = {"green", "blue", "purple", "red", "orange", "cyan"}

--转盘转动方向
local DIRECTION = {
    CLOCK_WISE = 1,             --顺时针
    ANTI_CLOCK_WISH = -1,       --逆时针
}

function GhostCaptainWheelView:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("GhostCaptain/GhostCaptain_WheelGame.csb") 

    self.m_endIndex = 0
    self:createWheelNode()

    self:createWheelView()
    self:createWheelSymbol()
end

--[[
    创建转盘
]]
function GhostCaptainWheelView:createWheelNode()
    local params = {
        doneFunc = handler(self,self.wheelDown),        --停止回调
        rotateNode = self:findChild("Node_wheel"),      --需要转动的节点
        sectorCount = MAX_WHEEL_COUNT,     --总的扇面数量
        direction = DIRECTION.CLOCK_WISE,       --转动方向
        parentView = self,  --父界面

        startSpeed = 0,     --开始速度
        minSpeed = 10,      --最小速度(每秒转动的角度)
        maxSpeed = 400,     --最大速度(每秒转动的角度)
        accSpeed = 250,      --加速阶段的加速度(每秒增加的角速度)
        reduceSpeed = 80,   --减速结算的加速度(每秒减少的角速度)
        turnNum = 2,         --开始减速前转动的圈数
        minDistance = 36,   --以最小速度行进的距离
        backDistance = 2,    --回弹距离
        backTime = 1.5      --回弹时间
    }
    self.m_wheel_node = util_require("Levels.BaseReel.BaseWheelNew"):create(params)
    self:addChild(self.m_wheel_node)
end

--[[
    创建转盘界面
]]
function GhostCaptainWheelView:createWheelView( )
    -- wheel次数框
    self.m_wheelNumsKuangNode = util_createAnimation("GhostCaptain_wheelGame_bar.csb")
    
    -- superwheel次数框
    self.m_wheelSuperNumsKuangNode = util_createAnimation("GhostCaptain_SuperwheelGame_bar.csb")
    if display.width < 1370 then
        local worldPos = gLobalActivityManager:getEntryArrowWorldPos()
        local pos = self.m_machine:findChild("Node_bonusGame"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        self.m_machine:findChild("Node_bonusGame"):addChild(self.m_wheelNumsKuangNode, 8)
        self.m_wheelNumsKuangNode:setPositionX(pos.x)
        self.m_wheelNumsKuangNode:setPositionY(self.m_machine:findChild("Node_wheelNums"):getPositionY())

        self.m_machine:findChild("Node_bonusGame"):addChild(self.m_wheelSuperNumsKuangNode, 9)
        self.m_wheelSuperNumsKuangNode:setPositionX(pos.x)
        self.m_wheelSuperNumsKuangNode:setPositionY(self.m_machine:findChild("Node_superWheelNums"):getPositionY())
    else
        self:findChild("Node_wheelbar"):addChild(self.m_wheelNumsKuangNode)
        self:findChild("Node_superwheelbar"):addChild(self.m_wheelSuperNumsKuangNode)
    end
    self.m_wheelNumsKuangNode:setVisible(false)
    self.m_wheelSuperNumsKuangNode:setVisible(false)

    -- free次数框
    self.m_freeNumsKuangNode = util_createAnimation("GhostCaptain_Superwheelgame_fgbar.csb")
    self:findChild("Node_fgbar"):addChild(self.m_freeNumsKuangNode)

    -- 光
    self.m_guangSpine = util_spineCreate("GhostCaptain_beiguang",true,true)
    self:findChild("Node_guang"):addChild(self.m_guangSpine)

    -- 船锚
    self.m_chuanMaoSpine = util_spineCreate("GhostCaptain_chuanmao",true,true)
    self:findChild("Node_chuanmao"):addChild(self.m_chuanMaoSpine)

    -- 粒子
    self.m_liZiSpine = util_spineCreate("GhostCaptain_zhuanpan",true,true)
    self:findChild("Node_guang"):addChild(self.m_liZiSpine)
    
    -- 光圈
    self.m_guangQuanSpine = util_spineCreate("GhostCaptain_zhuanpan",true,true)
    self:findChild("Node_guangquan"):addChild(self.m_guangQuanSpine)

    -- 中奖框
    self.m_winKuangNode = util_createAnimation("GhostCaptain_wheelgame_pick.csb")
    self:findChild("Node_pick_kuang"):addChild(self.m_winKuangNode)

    -- 中奖动画
    self.m_winKuangEffectNode = util_createAnimation("GhostCaptain_wheelgame_pick_tx.csb")
    self.m_winKuangNode:findChild("Node_tx"):addChild(self.m_winKuangEffectNode)
    self.m_winKuangEffectNode:runCsbAction("actionframe_zj", true)
    util_setCascadeOpacityEnabledRescursion(self.m_winKuangNode:findChild("Node_tx"), true)
    util_setCascadeColorEnabledRescursion(self.m_winKuangNode:findChild("Node_tx"), true)

    -- 赢钱框
    self.m_winCoinsKuangNode = util_createAnimation("GhostCaptain_wheelgame_reward.csb")
    self.m_machine:findChild("Node_bonusGame"):addChild(self.m_winCoinsKuangNode, 10)
    local pos = util_convertToNodeSpace(self.m_machine.m_bottomUI.coinWinNode, self.m_machine:findChild("Node_bonusGame"))
    self.m_winCoinsKuangNode:setPositionY(pos.y)
    self.m_winCoinsKuangNode:setVisible(false)

    -- 再来一次动画
    self.m_spinAgainNode = util_createAnimation("GhostCaptain_wheelgame_spinagain.csb")
    self.m_machine:findChild("Node_bonusGame"):addChild(self.m_spinAgainNode, 11)
    local guangNode = util_createAnimation("Socre_GhostCaptain_tb_guang.csb")
    self.m_spinAgainNode:findChild("Node_guang"):addChild(guangNode)
    guangNode:runCsbAction("idleframe", true)
    util_setCascadeOpacityEnabledRescursion(self.m_spinAgainNode:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self.m_spinAgainNode:findChild("Node_guang"), true)

    local saoguangSpine = util_spineCreate("spinagain_sg",true,true)
    self.m_spinAgainNode:findChild("sg"):addChild(saoguangSpine)
    util_spinePlay(saoguangSpine, "idle", true)
    self.m_spinAgainNode.saoguangSpine = saoguangSpine
    self.m_spinAgainNode:setVisible(false)

    -- 中奖相关
    self.m_winGuangSpine = util_spineCreate("GhostCaptain_zhezhao",true,true)
    self:findChild("Node_zhezhao"):addChild(self.m_winGuangSpine)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_zhezhao"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_zhezhao"), true)

    -- 切换super动画
    self.m_qiehuanEffectSpine = util_spineCreate("GhostCaptain_zhuanpan",true,true)
    self:findChild("Node_qiehuan"):addChild(self.m_qiehuanEffectSpine)
end

function GhostCaptainWheelView:createWheelSymbol()
    self.m_bigWheelNode = {}

    for i = 1, MAX_WHEEL_COUNT, 1 do
        local symbolNode = util_createAnimation("GhostCaptain_wheelgame_ditu.csb")
        self:findChild("Node_wheel_"..(i-1)):addChild(symbolNode)
        self.m_bigWheelNode[#self.m_bigWheelNode+1] = symbolNode

        symbolNode.m_jackpotNode = util_createAnimation("GhostCaptain_wheelgame_ditu_reward.csb")
        symbolNode:findChild("Node_ditu_reward_jackpot"):addChild(symbolNode.m_jackpotNode)
        symbolNode.m_coinsNode = {}
        for index = 1, 6 do
            symbolNode.m_coinsNode[index] = util_createAnimation("GhostCaptain_wheelgame_ditu_num.csb")
            symbolNode:findChild("Node_"..index):addChild(symbolNode.m_coinsNode[index])
        end
    end
end

--[[
    转盘开始出现
]]
function GhostCaptainWheelView:wheelStart()
    local bonusDate = self.m_machine.m_runSpinResultData.p_bonusExtra
    if bonusDate.triggerType == 3 then
        if bonusDate.normalTotal and bonusDate.superTotal and bonusDate.wheelBonusTimes ~= 0 then
            self.m_wheelNumsKuangNode:setVisible(true)
            self.m_wheelSuperNumsKuangNode:setVisible(true)
            if display.width < 1370 then
                self.m_wheelSuperNumsKuangNode:setPositionY(self.m_machine:findChild("Node_superWheelNums"):getPositionY())
            else
                self.m_wheelSuperNumsKuangNode:setPosition(cc.p(0, 0))
            end
        else
            if self.m_curShowWheelType == 1 then
                self.m_wheelNumsKuangNode:setVisible(true)
                self.m_wheelSuperNumsKuangNode:setVisible(false)
            else
                self.m_wheelNumsKuangNode:setVisible(false)
                self.m_wheelSuperNumsKuangNode:setVisible(true)
                self.m_wheelSuperNumsKuangNode:setPosition(util_convertToNodeSpace(self.m_wheelNumsKuangNode, self.m_wheelSuperNumsKuangNode:getParent()))
            end
        end
    else
        if bonusDate.normalTotal and bonusDate.normalTotal == 1 then
            self.m_wheelNumsKuangNode:setVisible(false)
        elseif bonusDate.superTotal and bonusDate.superTotal == 1 then
            self.m_wheelSuperNumsKuangNode:setVisible(false)
        else
            self.m_wheelNumsKuangNode:setVisible(bonusDate.triggerType == 1)
            self.m_wheelSuperNumsKuangNode:setVisible(bonusDate.triggerType == 2)
            if self.m_curShowWheelType == 2 then
                self.m_wheelSuperNumsKuangNode:setPosition(util_convertToNodeSpace(self.m_wheelNumsKuangNode, self.m_wheelSuperNumsKuangNode:getParent()))
            end
        end
    end
    self:findChild("superwheel_kuang"):setVisible(self.m_curShowWheelType == 2)
    self:findChild("wheel_kuang"):setVisible(self.m_curShowWheelType == 1)

    self.m_freeNumsKuangNode:setVisible(false)
    if bonusDate.addFreeTimes then
        self.m_freeNumsKuangNode:setVisible(true)
        self.m_freeNumsKuangNode:findChild("m_lb_num"):setString(bonusDate.addFreeTimes)
        self.m_freeNumsKuangNode:runCsbAction("start")
    end

    if bonusDate.wheelBonusTimes then
        self.m_wheelNumsKuangNode:findChild("m_lb_num"):setString(bonusDate.wheelBonusTimes)
        self.m_wheelNumsKuangNode:runCsbAction("start")
    end
    if bonusDate.superWheelBonusTimes then
        self.m_wheelSuperNumsKuangNode:findChild("m_lb_num"):setString(bonusDate.superWheelBonusTimes)
        self.m_wheelSuperNumsKuangNode:runCsbAction("start")
    end
    
    self.m_chuanMaoSpine:setVisible(true)
    util_spinePlay(self.m_chuanMaoSpine, "start", false)

    --显示转盘背光
    self.m_guangSpine:setVisible(true)
    util_spinePlay(self.m_guangSpine, "start_guang", false)
end

--[[
    刷新转盘
]]
function GhostCaptainWheelView:updateWheelSymbol( )
    local bonusDate = self.m_machine.m_runSpinResultData.p_bonusExtra
    self.m_liZiSpine:setVisible(false)
    self.m_guangQuanSpine:setVisible(false)
    self.m_spinAgainNode:setVisible(false)
    self.m_winGuangSpine:setVisible(false)
    self.m_chuanMaoSpine:setVisible(false)
    self.m_winKuangEffectNode:setVisible(false)
    self.m_qiehuanEffectSpine:setVisible(false)
    self.m_guangSpine:setVisible(false)
    self.m_wheelNumsKuangNode:setVisible(false)
    self.m_wheelSuperNumsKuangNode:setVisible(false)
    if bonusDate and bonusDate.bonusWin and bonusDate.bonusWin > 0 then
        self.m_winCoinsKuangNode:setVisible(true)
        self.m_winCoinsKuangNode:runCsbAction("idle")
        self.m_winCoinsKuangNode:findChild("m_lb_coins"):setString(util_formatCoins(bonusDate.bonusWin, 50))
        self:updateLabelSize({label=self.m_winCoinsKuangNode:findChild("m_lb_coins"),sx=1,sy=1},764)  
    else
        self.m_winCoinsKuangNode:setVisible(false)
    end

    -- 判断转盘类型
    if bonusDate.triggerType == 3 then
        if bonusDate.wheelBonusTimes then
            self.m_curShowWheelType = 1
            if bonusDate.wheelBonusTimes == 0 then
                self.m_curShowWheelType = 2
            end
        elseif bonusDate.superWheelBonusTimes then
            self.m_curShowWheelType = 2
        end
    else
        self.m_curShowWheelType = bonusDate.triggerType
    end
    self:showWheelSymbol(bonusDate)
end

--[[
    根据服务器给的数据  显示转盘
]]
function GhostCaptainWheelView:showWheelSymbol(_bonusDate)
    local wheelTypeOrder = _bonusDate.nextwheelTypeOrder and _bonusDate.nextwheelTypeOrder or _bonusDate.wheelTypeOrder
    local wheelMul = _bonusDate.nextwheelMul and _bonusDate.nextwheelMul or _bonusDate.wheelMul
    local strlist = util_string_split(wheelTypeOrder, ";")
    for index, type in ipairs(strlist) do
        for _type, _mul in pairs(wheelMul) do
            if type == _type then
                for _, _bgName in ipairs(ALL_ITEM_BG) do
                    self.m_bigWheelNode[index]:findChild(_bgName):setVisible(_bgName == ITEM_BG[type])
                end
                if type == "free1" or type == "free2" then
                    self.m_bigWheelNode[index]:findChild("Node_shuzhi"):setVisible(false)
                    self.m_bigWheelNode[index]:findChild("Node_ditu_reward_jackpot"):setVisible(true)
                    self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_jackpot"):setVisible(false)
                    self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double"):setVisible(false)
                    self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_fg"):setVisible(true)
                    self.m_bigWheelNode[index].m_jackpotNode:findChild("m_lb_num"):setString(_mul)
                elseif type == "mini" or type == "minor" or type == "major" or type == "grand" then
                    self.m_bigWheelNode[index]:findChild("Node_shuzhi"):setVisible(false)
                    self.m_bigWheelNode[index]:findChild("Node_ditu_reward_jackpot"):setVisible(true)
                    self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_fg"):setVisible(false)
                    if self.m_curShowWheelType == 1 then
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_jackpot"):setVisible(true)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double"):setVisible(false)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("mini"):setVisible("mini" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("minor"):setVisible("minor" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("major"):setVisible("major" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("grand"):setVisible("grand" == type)
                    else
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_jackpot"):setVisible(false)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double"):setVisible(true)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double_mini"):setVisible("mini" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double_minor"):setVisible("minor" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double_major"):setVisible("major" == type)
                        self.m_bigWheelNode[index].m_jackpotNode:findChild("Node_double_grand"):setVisible("grand" == type)
                    end
                    self.m_bigWheelNode[index].m_jackpotNode.jackpotType = type
                else
                    self.m_bigWheelNode[index]:findChild("Node_shuzhi"):setVisible(true)
                    self.m_bigWheelNode[index]:findChild("Node_ditu_reward_jackpot"):setVisible(false)
                    self:updateSymbolCoins(index, _mul)
                end
            end
        end
    end
end

--[[
    刷新钱数
]]
function GhostCaptainWheelView:updateSymbolCoins(_index, _mul)
    local score = util_formatCoins(_mul * globalData.slotRunData:getCurTotalBet(), 4, true)
    local coinsList = {}
    for _subNum = 1, string.len(score) do
       table.insert(coinsList, string.sub(score, _subNum, _subNum)) 
    end
    for _nodeIndex = 1, 6 do
        self.m_bigWheelNode[_index]:findChild("Node_".._nodeIndex):setVisible(false)
    end
    for _nodeIndex, _str in ipairs(coinsList) do
        if _nodeIndex <= 6 then
            self.m_bigWheelNode[_index]:findChild("Node_".._nodeIndex):setVisible(true)
            self.m_bigWheelNode[_index].m_coinsNode[_nodeIndex]:findChild("m_lb_num"):setString(_str)
        end
    end
end

-- 转盘转动结束调用
function GhostCaptainWheelView:initCallBack(callBackFun)
    self.m_callFunc = function(_func)
        callBackFun(_func)
    end
end

function GhostCaptainWheelView:onEnter()
    GhostCaptainWheelView.super.onEnter(self)
end

function GhostCaptainWheelView:onExit()
    GhostCaptainWheelView.super.onExit(self)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function GhostCaptainWheelView:beginWheel()

    self:sendData()
end

--[[
    开始转动
]]
function GhostCaptainWheelView:beginWheelAction()
    self.m_liZiSpine:setVisible(true)
    self.m_guangQuanSpine:setVisible(true)
    util_spinePlay(self.m_liZiSpine, "actionframe", false)
    util_spinePlay(self.m_guangQuanSpine, "actionframe_up", false)
    util_spinePlay(self.m_chuanMaoSpine, "idle", true)
    self.m_wheel_node:startMove()
    self.m_soundTurnId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_zhanpan_start_turn)
end

--[[
    再一次转动
]]
function GhostCaptainWheelView:againBeginWheelAction()
    if self.m_bonusData.bonus and self.m_bonusData.bonus.status and self.m_bonusData.bonus.status == "CLOSED" then
        self.m_callFunc(function()
            self:updateCoinsByEnd()
        end)
        return
    end

    self.m_liZiSpine:setVisible(false)
    self.m_guangQuanSpine:setVisible(false)
    self:runCsbAction("actionframe_fgover", false, function()
        self.m_winGuangSpine:setVisible(false)
    end)
    self.m_winKuangNode:runCsbAction("over", false, function()
        self.m_winKuangEffectNode:setVisible(false)
    end)

    local beginAgainWheel = function()
        self.m_spinAgainNode:setVisible(true)
        self.m_spinAgainNode:findChild("Node_all"):setVisible(true)
        self.m_spinAgainNode:findChild("Node_super"):setVisible(false)
        self.m_spinAgainNode.saoguangSpine:setVisible(false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_spinAgain)
        self.m_spinAgainNode:runCsbAction("start", false, function()
            self.m_spinAgainNode.saoguangSpine:setVisible(true)
            util_spinePlay(self.m_spinAgainNode.saoguangSpine, "idle", true)
        end)
        performWithDelay(self, function()
            self.m_spinAgainNode.saoguangSpine:setVisible(false)
            self.m_spinAgainNode:runCsbAction("over", false, function()
                self.m_spinAgainNode:setVisible(false)
                self:beginWheel()
            end)
        end,2)
    end

    local extra = self.m_bonusData.bonus.extra or {} 
    if extra.triggerType == 3 and self.m_curShowWheelType == 2 then
        if self.m_wheelNumsKuangNode:isVisible() then
            self.m_spinAgainNode:setVisible(true)
            self.m_spinAgainNode:findChild("Node_all"):setVisible(false)
            self.m_spinAgainNode:findChild("Node_super"):setVisible(true)
            self.m_spinAgainNode.saoguangSpine:setVisible(false)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_spinAgain)
            self.m_spinAgainNode:runCsbAction("start", false, function()
                self.m_spinAgainNode.saoguangSpine:setVisible(true)
                util_spinePlay(self.m_spinAgainNode.saoguangSpine, "idle2", true)
            end)
            performWithDelay(self, function()
                self.m_spinAgainNode.saoguangSpine:setVisible(false)
                self.m_spinAgainNode:runCsbAction("over", false, function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_change)
                    self.m_spinAgainNode:setVisible(false)
                    self.m_qiehuanEffectSpine:setVisible(true)
                    util_spinePlay(self.m_qiehuanEffectSpine, "actionframe_switch", false)
                    self:runCsbAction("actionframe_switch", false, function()
                        self:beginWheel()
                    end)
                    performWithDelay(self, function(  )
                        self:showWheelSymbol(extra)
                        self.m_wheel_node:resetViewStatus()
                        self:findChild("superwheel_kuang"):setVisible(self.m_curShowWheelType == 2)
                        self:findChild("wheel_kuang"):setVisible(self.m_curShowWheelType == 1)
                    end, 18/30)

                    self.m_wheelNumsKuangNode:runCsbAction("over", false, function()
                        self.m_wheelNumsKuangNode:setVisible(false)
                    end)
                    self.m_wheelSuperNumsKuangNode:setVisible(true)
                    self.m_wheelSuperNumsKuangNode:findChild("m_lb_num"):setString(extra.superWheelBonusTimes)
                    local endPos = util_convertToNodeSpace(self.m_wheelNumsKuangNode, self.m_wheelSuperNumsKuangNode:getParent())
                    local seq = cc.Sequence:create({
                        cc.EaseSineInOut:create(cc.MoveTo:create(30/60, endPos)),
                    })
                    self.m_wheelSuperNumsKuangNode:runAction(seq)
                    self.m_wheelSuperNumsKuangNode:runCsbAction("switch", false)
                end)
            end,2)
            
            return
        end
    end

    beginAgainWheel()
end

--[[
    转盘停止
]]
function GhostCaptainWheelView:wheelDown()
    if self.m_soundTurnId then
        gLobalSoundManager:stopAudio(self.m_soundTurnId)
        self.m_soundTurnId = nil
    end
    util_spineMix(self.m_chuanMaoSpine, "idle", "idleframe", 6/30)
    util_spinePlay(self.m_chuanMaoSpine, "idleframe", true)
    self:runCsbAction("idle")
    self.m_winGuangSpine:setVisible(true)
    util_spinePlay(self.m_winGuangSpine, "actionframe_fg", false)
    util_spineEndCallFunc(self.m_winGuangSpine,"actionframe_fg",function ()
        util_spinePlay(self.m_winGuangSpine, "actionframe_fgidle", true)
    end)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_zhanpan_selected)
    self.m_winKuangEffectNode:setVisible(true)
    self.m_winKuangNode:runCsbAction("start", false)
    performWithDelay(self, function()
        local jackpotNode = self.m_bigWheelNode[self.m_endIndex+1].m_jackpotNode
        local jackpotChildRenNode = jackpotNode:findChild("Node_1")
        if self.m_curShowWheelType == 2 and jackpotNode:findChild("Node_double"):isVisible() then
            if jackpotNode.jackpotType == "grand" then
                jackpotChildRenNode = jackpotNode:findChild("Node_2")
            elseif jackpotNode.jackpotType == "major" then
                jackpotChildRenNode = jackpotNode:findChild("Node_3")
            elseif jackpotNode.jackpotType == "minor" then
                jackpotChildRenNode = jackpotNode:findChild("Node_4")
            elseif jackpotNode.jackpotType == "mini" then
                jackpotChildRenNode = jackpotNode:findChild("Node_5")
            end
        end
        jackpotNode.oldParent = jackpotChildRenNode:getParent()
        local pos = util_convertToNodeSpace(jackpotChildRenNode, self:findChild("Node_pick_kuang"))
        util_changeNodeParent(self:findChild("Node_pick_kuang"), jackpotChildRenNode, 10)
        jackpotChildRenNode:setPosition(pos)
        jackpotNode:runCsbAction("actionframe", false, function()
            util_changeNodeParent(jackpotNode.oldParent, jackpotChildRenNode, 0)
            jackpotChildRenNode:setPosition(cc.p(0, 50))
        end)
    end, 5/60)

    performWithDelay(self, function()
        local funCallBack = function()
            if not self.m_winCoinsKuangNode:isVisible() then
                self.m_winCoinsKuangNode:findChild("m_lb_coins"):setString("")
                self.m_winCoinsKuangNode:setVisible(true)
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_jiesuanKuang_start)
                self.m_winCoinsKuangNode:runCsbAction("start", false, function()
                    self:showUpdateWinCoinsUI()
                end)
            else
                self:showUpdateWinCoinsUI()
            end
        end

        local extra = self.m_bonusData.bonus.extra or {}
        -- 中奖jackpot
        if extra.hitType == "grand" or extra.hitType == "major" or extra.hitType == "minor" or extra.hitType == "mini" then
            local winJackpotCoins = self:getJackpotWinCoins()
            local curShowWheelType = self.m_curShowWheelType
            if extra.wheelBonusTimes and self.m_curShowWheelType == 2 then
                curShowWheelType = 1
            end
            self.m_machine:showJackpotView(winJackpotCoins, extra.hitType, curShowWheelType, function()
                funCallBack()
            end)
        -- 中奖free
        elseif extra.hitType == "free1" or extra.hitType == "free2" then
            self.m_freeNumsKuangNode:setVisible(false)
            if not self.m_freeNumsKuangNode:isVisible() then
                self.m_freeNumsKuangNode:findChild("m_lb_num"):setString(extra.addFreeTimes)
                self.m_freeNumsKuangNode:setVisible(true)
                self.m_freeNumsKuangNode:runCsbAction("start", false, function()
                    performWithDelay(self, function()
                        self:againBeginWheelAction()
                    end, 0.5)
                end)
            else
                self.m_freeNumsKuangNode:findChild("m_lb_num"):setString(extra.addFreeTimes)
                performWithDelay(self, function()
                    self:againBeginWheelAction()
                end, 0.5)
            end
        -- 中奖钱
        else
            funCallBack()
        end
    end, 54/60 + 1)
end

--[[
    获取jackpot的钱数
]]
function GhostCaptainWheelView:getJackpotWinCoins( )
    local extra = self.m_bonusData.bonus.extra
    if self.m_bonusData.jackpotCoins then
        for _jpType, _jackpotCoins in pairs(self.m_bonusData.jackpotCoins) do
            if string.lower(_jpType) == extra.hitType then
                return _jackpotCoins
            end
        end
    end
    return 0
end

--[[
    刷新赢钱区的钱
]]
function GhostCaptainWheelView:showUpdateWinCoinsUI()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_jiesuanKuang_coins_start)
    self.m_coinsJumpSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_wheel_jiesuanKuang_coins_jump)
    local extra = self.m_bonusData.bonus.extra
    self.m_winCoinsKuangNode:runCsbAction("actionframe", false)
    self:jumpCoins(extra.bonusWin, function()
        if self.m_coinsJumpSoundId then
            gLobalSoundManager:stopAudio(self.m_coinsJumpSoundId)
            self.m_coinsJumpSoundId = nil
        end
        performWithDelay(self, function()
            self:againBeginWheelAction()
        end, 1.5)
    end)
end

--[[
    滚动加钱
]]
function GhostCaptainWheelView:jumpCoins(_coins, _callBack)
    local node = self.m_winCoinsKuangNode:findChild("m_lb_coins")
    local curCoins = self:getCurWinCoins(node)
    -- time 固定 1.5
    local coinRiseNum = (_coins - curCoins) / (1.5 * 60)
    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum )
    
    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
        curCoins = curCoins + coinRiseNum
        if curCoins >= _coins then
            curCoins = _coins
            
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1}, 764)
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if _callBack then
                _callBack()
            end
        else
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1}, 764)
        end
    end)
end

--[[
    获取赢钱框的钱
]]
function GhostCaptainWheelView:getCurWinCoins(_node)
    local winCoin = 0
    local sCoins = _node:getString()
    if "" == sCoins then
        return winCoin
    end
    local numList = util_string_split(sCoins,",")
    local numStr = ""
    for i,v in ipairs(numList) do
        numStr = numStr .. v
    end
    winCoin = tonumber(numStr) or 0
    return winCoin
end
--[[
    设置停止索引
]]
function GhostCaptainWheelView:setWheelEndIndex()
    local extra = self.m_bonusData.bonus.extra or {}
    local endIndex = 1
    if extra.wheelTypeOrder then
        local strlist = util_string_split(extra.wheelTypeOrder, ";")
        for index, type in ipairs(strlist) do
            if type == extra.hitType then
                endIndex = index - 1
                break
            end
        end
        self.m_endIndex = endIndex
        self.m_wheel_node:setEndIndex(endIndex)
    end
end

--[[
    重置转盘角度
]]
function GhostCaptainWheelView:resetWheel()
    self.m_wheel_node:resetViewStatus()
end

function GhostCaptainWheelView:sendData()
    local httpSendMgr = SendDataManager:getInstance()
    local messageData={ msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

function GhostCaptainWheelView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            dump(spinData.result, "featureResultCallFun data", 3)
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            print("赢取的总钱数为=" .. self.m_totleWimnCoins)
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(spinData.result)
            end
        else
            -- 处理消息请求错误情况
            gLobalViewManager:showReConnect()
        end
    end
end

--[[
    是否变化super转盘
]]
function GhostCaptainWheelView:changeSuperWheel( )
    local bonusData = self.m_bonusData.bonus.extra
    -- 判断转盘类型
    if bonusData.triggerType == 3 then
        if bonusData.wheelBonusTimes and bonusData.wheelBonusTimes ~= 0 then
            self.m_curShowWheelType = 1
        elseif bonusData.superWheelBonusTimes then
            self.m_curShowWheelType = 2
        end
    else
        self.m_curShowWheelType = bonusData.triggerType
    end
end

function GhostCaptainWheelView:recvBaseData(_data)
    self.m_bonusData = _data
    self:updataWheelNums()
    self:changeSuperWheel()
    if _data.bonus.status == "CLOSED" then
        self.m_bonusData.bonus.bsWinCoins = self.m_bonusData.bonus.extra.bonusWin
        
        -- 中奖了free玩法
        if #_data.features > 1 and _data.features[2] == 1 then
            self.m_machine:addFreeSpinEffect()
            globalData.slotRunData.totalFreeSpinCount = _data.freespin.freeSpinsTotalCount
            globalData.slotRunData.freeSpinCount = _data.freespin.freeSpinsLeftCount
            self.m_machine.m_iFreeSpinTimes = _data.freespin.freeSpinsTotalCount
            if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
                self.m_machine.m_runSpinResultData.p_freeSpinNewCount = _data.freespin.freeSpinsTotalCount
            end
            self.m_machine.m_wheelToFree = true
        end

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{_data.bonus.bsWinCoins, GameEffect.EFFECT_BONUS})
    end

    self:beginWheelAction()
    self:setWheelEndIndex()
end

--[[
    转盘结束 刷新金币
]]
function GhostCaptainWheelView:updateCoinsByEnd( )
    local lastCoins = self.m_machine:getCurBottomWinCoins()
    self.m_machine:setLastWinCoin(lastCoins + self.m_bonusData.bonus.extra.bonusWin)
    if self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_machine:updateBottomUICoins(0, self.m_bonusData.bonus.extra.bonusWin, false, true, false)
    else
        self.m_machine:updateBottomUICoins(0, self.m_bonusData.bonus.extra.bonusWin, true, true, false)
    end
end

--[[
    刷新转盘次数
]]
function GhostCaptainWheelView:updataWheelNums( )
    local bonusData = self.m_bonusData.bonus.extra
    if bonusData.superTotal then
        self.m_wheelNumsKuangNode:findChild("m_lb_num"):setString(bonusData.wheelBonusTimes)
        self.m_wheelSuperNumsKuangNode:findChild("m_lb_num"):setString(bonusData.superWheelBonusTimes)
    else
        self.m_wheelNumsKuangNode:findChild("m_lb_num"):setString(bonusData.wheelBonusTimes)
    end
end

return GhostCaptainWheelView