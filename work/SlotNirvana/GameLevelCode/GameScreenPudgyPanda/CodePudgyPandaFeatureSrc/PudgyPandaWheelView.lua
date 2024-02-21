---
--smy
--2018年4月18日
--PudgyPandaWheelView.lua
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaWheelView = class("PudgyPandaWheelView",util_require("Levels.BaseLevelDialog"))

function PudgyPandaWheelView:initUI(params)
    self.m_machine = params.machine
    self._endCallFunc = params._endCallFunc
    self._wheelEndIndex = params._wheelEndIndex
    self._curFreeCountData = params._curFreeCountData

    self:createCsbNode("PudgyPanda_FatFeature_Wheel.csb")

    -- 提示
    self.m_tipsAni = util_createAnimation("PudgyPanda_wheel_tishi.csb")
    self:findChild("Node_wheel_tishi"):addChild(self.m_tipsAni)
    self.m_tipsAni:setVisible(false)

    -- 轮盘玩法，上边的光效
    self.m_lightAni = util_createAnimation("PudgyPanda_zptx.csb")
    self:findChild("Node_light"):addChild(self.m_lightAni)
    self.m_lightAni:setVisible(false)

    self.m_lightSpine = util_spineCreate("PudgyPanda_zptx",true,true)
    util_spinePlay(self.m_lightSpine, "idle", true)
    self.m_lightAni:findChild("Node_root"):addChild(self.m_lightSpine)
    util_setCascadeOpacityEnabledRescursion(self.m_lightAni, true)

    self.m_tipsIsShow = false

    --创建竖向滚轮
    self.m_reel_vertical = self:createSpecialReeVertical()
    
    self:findChild("sp_wheel"):addChild(self.m_reel_vertical)
    self.m_reel_vertical:initSymbolNode()

    self:addClick(self:findChild("sp_wheel"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitTipsNode = cc.Node:create()
    self:addChild(self.m_scWaitTipsNode)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PudgyPandaWheelView:onEnter()
    PudgyPandaWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(self, params)
        self:featureResultCallFun(params)
    end, ViewEventType.NOTIFY_GET_SPINRESULT)
end

--[[
    创建特殊轮子-纵向
]]
function PudgyPandaWheelView:createSpecialReeVertical()
    local sp_wheel = self:findChild("sp_wheel")
    local wheelSize = sp_wheel:getContentSize()
    local reelData = self.m_machine.m_runSpinResultData.p_bonusExtra.wheel_config
    local reelNode =  util_require("CodePudgyPandaFeatureSrc.PudgyPandaWheelVertical"):create({
        parentData = {
            reelDatas = reelData,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width,
            slotNodeH = wheelSize.height,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false
        },      --列数据
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 1,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = 0.15,
            p_reelResDis = 4,
            p_reelRunDatas = {20}
        },      --列配置数据
        doneFunc = function()--列停止回调
            util_spinePlay(self.m_lightSpine, "actionframe", false)
            util_spineEndCallFunc(self.m_lightSpine, "actionframe", function()
                self.m_lightAni:setVisible(false)
            end) 
            self.m_machine:playTriggerRole()
            local symbolNode = self.m_reel_vertical:getSymbolByRow(1)
            local bulingName = "buling"
            local idleName = "idleframe"
            local jieSuanName = "js"
            local rewardType = symbolNode.jackpotType
            if symbolNode then
                if symbolNode.jackpotType ~= "" then
                    bulingName = "buling_j"
                    idleName = "idleframe_j"
                    jieSuanName = "js_j"
                end
                if self.m_startMoveSound then
                    gLobalSoundManager:stopAudio(self.m_startMoveSound)
                    self.m_startMoveSound = nil
                end
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Wheel_SelectReward)
                symbolNode:runAnim(bulingName, false, function()
                    symbolNode:runAnim(idleName, true)
                end)
            end
            -- 结算动画
            self.m_machine:delayCallBack(1.0,function()
                local hideSelf = function()
                    self:removeFromParent()
                end
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Wheel_Select_ShowReward)
                symbolNode:runAnim(jieSuanName, false, function()
                    symbolNode:runAnim(idleName, true)
                    self.m_machine:bonusGameOver(self._endCallFunc, hideSelf, rewardType)
                end)
            end)
        end,        
        createSymbolFunc = function(symbolType, rowIndex, colIndex, isLastNode)--创建小块
            local symbolNode = self:createWheelNode(symbolType)
            symbolNode.m_isLastSymbol = isLastNode
            return symbolNode
        end,
        pushSlotNodeToPoolFunc = function(symbolType,symbolNode)
            
        end,--小块放回缓存池
        updateGridFunc = function(symbolNode)
            
        end,  --小块数据刷新回调
        direction = 0,      --0纵向 1横向 默认纵向
        colIndex = 1,
        machine = self.m_machine      --必传参数
    })

    return reelNode
end

function PudgyPandaWheelView:getCurRewardIsJackpot(symbolType)
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    local jackpotType = ""
    for i,jackpotCfg in ipairs(jackpotPools) do
        if jackpotCfg.p_configData.p_multiple == symbolType then
            jackpotType = jackpotCfg.p_configData.p_name
        end
    end
    return jackpotType
end

function PudgyPandaWheelView:createWheelNode(symbolType)
    local jackpotType = self:getCurRewardIsJackpot(symbolType)

    local symbolNode = self.m_machine:createPudgyPandaSymbol(self.m_machine.SYMBOL_SCORE_BONUS_MAJOR)
    local spineNode = symbolNode:getNodeSpine()
    if jackpotType == "GRAND" then
        self:setFreeSpecialSymbolSkin(spineNode, "GRAND")
        symbolNode:runAnim("idleframe_j", true)
        symbolNode.jackpotType = "grand"
        return symbolNode
    elseif jackpotType == "MEGA" then
        self:setFreeSpecialSymbolSkin(spineNode, "mega")
        symbolNode:runAnim("idleframe_j", true)
        symbolNode.jackpotType = "mega"
        return symbolNode
    elseif jackpotType == "MAJOR" then
        self:setFreeSpecialSymbolSkin(spineNode, "major")
        symbolNode:runAnim("idleframe_j", true)
        symbolNode.jackpotType = "major"
        return symbolNode
    end
    
    symbolNode.jackpotType = ""
    local scoreNode = util_createAnimation("PudgyPanda_Bonus_coins.csb")
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local coins = util_formatCoins(lineBet * symbolType, 3)

    symbolNode:runAnim("idleframe", true)
    scoreNode:findChild("m_lb_coins"):setString(coins)
    util_spinePushBindNode(spineNode, "zi", scoreNode)
    self:setFreeSpecialSymbolSkin(spineNode, "zi")
    return symbolNode
end

function PudgyPandaWheelView:setFreeSpecialSymbolSkin(_spineNode, _skinName)
    local spineNode = _spineNode
    local skinName = _skinName
    spineNode:setSkin(skinName)
end

--默认按钮监听回调
function PudgyPandaWheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self:sendData()
end

--[[
    数据发送
]]
function PudgyPandaWheelView:sendData()
    if self.m_isWaiting then
        return
    end
    --防止连续点击
    self.m_isWaiting = true
    self.m_startMoveSound = gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Wheel_StartMove)
    self.m_lightAni:setVisible(true)
    util_spinePlay(self.m_lightSpine, "idle", true)
    self.m_lightAni:runCsbAction("start", false, function()
        self.m_lightAni:runCsbAction("idle", true)
    end)
    self.m_machine:refreshWheelSpinBarLeftCount()
    self.m_machine:setWheelBtnState(false)
    
    self.m_scWaitNode:stopAllActions()
    self:closeTips(true)
    self.m_reel_vertical:startMove(nil, true)
    
    local httpSendMgr = SendDataManager:getInstance()
    -- -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT,betLevel = self.m_machine.m_iBetLevel}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

function PudgyPandaWheelView:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            self:recvBaseData(spinData.result)
        end
    else
        gLobalViewManager:showReConnect(true)
    end
end


--[[
    接收数据
]]
function PudgyPandaWheelView:recvBaseData(featureData)
    self.m_featureData = featureData
    --更新machine数据 
    self.m_machine.m_runSpinResultData:parseResultData(featureData, self.m_machine.m_lineDataPool)
    --计算停轮时的轮盘
    local endIndex = 1
    local reelData = self.m_machine.m_runSpinResultData.p_bonusExtra.wheel_config
    if self.m_machine.m_runSpinResultData.p_bonusExtra.wheel_pick then
        local wheelPick = self.m_machine.m_runSpinResultData.p_bonusExtra.wheel_pick + 1
        -- self.m_rewardType = reelData[wheelPick]
        -- self.m_rewardType = self:getCurRewardIsJackpot(reelData[wheelPick])
        endIndex = wheelPick
    end
    local lastList = {}
    for index = 1, #reelData do
        local symbolType = reelData[endIndex + index - 1]
        if symbolType then
            lastList[#lastList + 1] = symbolType
        end
    end

    self.m_reel_vertical:setSymbolList(lastList)

    self.m_reel_vertical.m_needDeceler = true
    self.m_reel_vertical.m_runTime = 0
end

-- 显示提示
function PudgyPandaWheelView:showTips()
    -- 转盘缓动
    self.m_reel_vertical:startMove()

    -- 提示
    self.m_tipsIsShow = true
    self.m_tipsAni:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Wheel_ShowTips)
    self.m_tipsAni:runCsbAction("start", false, function()
        self.m_tipsAni:runCsbAction("idle", true)
    end)
    self:closeTips()
end

-- 关闭提示
function PudgyPandaWheelView:closeTips(_isClick)
    if not self.m_tipsIsShow then
        return
    end
    self.m_scWaitTipsNode:stopAllActions()
    local delayTime = 0
    if not _isClick then
        delayTime = 5.0
    end
    performWithDelay(self.m_scWaitTipsNode, function()
        self.m_tipsIsShow = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Wheel_CloseTips)
        self.m_tipsAni:runCsbAction("over", false, function()
            self.m_tipsAni:setVisible(false)
        end)
    end, delayTime)
end

-- 重置数据(继续转轮盘)
function PudgyPandaWheelView:resetWheelData()
    self.m_isWaiting = false
    self.m_machine:setWheelBtnState(true)
    self.m_reel_vertical:resetData()
end

-- 刚创建不让点击
function PudgyPandaWheelView:setWheelData()
    self.m_isWaiting = true
    self.m_machine:setWheelBtnState(false)
end

-- 移除
function PudgyPandaWheelView:hideSelf()
    self:removeFromParent()
end

return PudgyPandaWheelView