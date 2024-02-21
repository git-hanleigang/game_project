---
--smy
--2018年4月18日
--LuxeVegasSmallWheelView.lua
local LuxeVegasSmallWheelView = class("LuxeVegasSmallWheelView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "LuxeVegasPublicConfig"

function LuxeVegasSmallWheelView:initUI(params)
    self.m_machine = params.machine
    self.m_wheelConfig = params._wheelConfig
    self.m_wheelResult = params._wheelResult
    self.m_endCallFunc = params._endCallFunc

    self:createCsbNode("LuxeVegas_BonusWheel.csb")

    self.m_rewardNode = self:findChild("Node_award")

    self.m_initShow = true

    --创建竖向滚轮
    self.m_reel_vertical = self:createSpecialReeVertical()
    
    self:findChild("sp_wheel"):addChild(self.m_reel_vertical)
    self.m_reel_vertical:initSymbolNode()

    -- 收集旋涡node
    self.m_collectLightNode = self:findChild("Node_collectLight")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

-- 等小转盘bonus，actionframe播45帧再播放小转盘动画
function LuxeVegasSmallWheelView:playStartWheel()
    self:runCsbAction("start", false, function()
         self:runCsbAction("idle2A", false, function()
            self.m_initShow = false
            self.m_soundMove = gLobalSoundManager:playSound(PublicConfig.Music_SmallWheel_Start_Move,false)
            self:runCsbAction("idle2B", true)
            self.m_reel_vertical:startMove()
            self.m_reel_vertical.m_needDeceler = true
            self.m_reel_vertical.m_runTime = 0
         end)
    end)
end

function LuxeVegasSmallWheelView:onEnter()
    LuxeVegasSmallWheelView.super.onEnter(self)
end

-- 渐隐消失;光效node
function LuxeVegasSmallWheelView:setFadeOutAct()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over_all", false)
    for i=1, 3 do
        local spLight = self:findChild("sp_fade_"..i)
        spLight:runAction(cc.FadeOut:create(0.5))
    end
end

-- 特殊奖励光效
function LuxeVegasSmallWheelView:startSpecialLight()
    gLobalSoundManager:playSound(PublicConfig.Music_SmallWheel_Select_FeedBack)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start_all", false, function()
        self:runCsbAction("idle_all", true)
    end)
end

--[[
    创建特殊轮子-横向
]]
function LuxeVegasSmallWheelView:createSpecialReeVertical()
    local sp_wheel = self:findChild("sp_wheel")
    local wheelSize = sp_wheel:getContentSize()
    local reelNode =  util_require("CodeLuxeVegasSrc.LuxeVegasSmallWheelVertical"):create({
        _wheelNode = self,
        parentData = {
            reelDatas = self.m_wheelConfig,
            beginReelIndex = 1,
            slotNodeW = wheelSize.width,
            slotNodeH = wheelSize.height / 5,
            reelHeight = wheelSize.height,
            reelWidth = wheelSize.width,
            isDone = false,
            _machine = self.m_machine,
        },      --列数据
        configData = {
            p_reelMoveSpeed = 1000,
            p_rowNum = 6,
            p_reelBeginJumpTime = 0.2,
            p_reelBeginJumpHight = 20,
            p_reelResTime = 0.15,
            p_reelResDis = 4,
            p_reelRunDatas = {35}
        },      --列配置数据
        doneFunc = function()--列停止回调
            local curMul = self.m_wheelResult[2]
            -- 把奖励添加到对应节点上；特效需要
            local rewardNode = self:createWheelNode(curMul)
            self.m_rewardNode:addChild(rewardNode)
            self.m_machine:delayCallBack(0.1,function()
                if self.m_soundMove then
                    gLobalSoundManager:stopAudio(self.m_soundMove)
                    self.m_soundMove = nil
                end
                gLobalSoundManager:playSound(PublicConfig.Music_SmallWheel_Select)
                if curMul > 300 then
                    gLobalSoundManager:playSound(PublicConfig.Music_Colful_KeepUp)
                elseif curMul > 200 and curMul < 300 then
                    gLobalSoundManager:playSound(PublicConfig.Music_WheelBonus_AwardAll)
                elseif curMul == 10 then
                    gLobalSoundManager:playSound(PublicConfig.Music_MaxMul_Free)
                elseif curMul > 1 and curMul < 10 then
                    if not self.m_machine.m_smallWheelSoundIndex or self.m_machine.m_smallWheelSoundIndex >= 4 then
                        self.m_machine.m_smallWheelSoundIndex = 1
                    else
                        self.m_machine.m_smallWheelSoundIndex = self.m_machine.m_smallWheelSoundIndex + 1
                    end
                    local soundName = PublicConfig.Music_SmallWheel_Mul[self.m_machine.m_smallWheelSoundIndex]
                    if soundName then
                        gLobalSoundManager:playSound(soundName)
                    end
                end
                self:runCsbAction("actionframe", false, function()
                    local delayTime = 0
                    self:runCsbAction("idle", false, function()
                        self.m_collectLightNode:setVisible(curMul~=201)
                        if curMul > 200 then
                            if curMul == 201 then
                                if not tolua.isnull(self) then
                                    self:runCsbAction("idle", true)
                                end
                            else
                                delayTime = 25/60
                                gLobalSoundManager:playSound(PublicConfig.Music_SmallWheel_Collect)
                                self:runCsbAction("actionframe3", false, function()
                                    if not tolua.isnull(self) then
                                        self:runCsbAction("idle", true)
                                    end
                                end)
                            end
                        else
                            delayTime = 25/60
                            gLobalSoundManager:playSound(PublicConfig.Music_SmallWheel_Collect)
                            self:runCsbAction("actionframe2", false)
                        end
                        performWithDelay(self.m_scWaitNode, function()
                            if type(self.m_endCallFunc) == "function" then
                                self.m_endCallFunc()
                            end
                        end, delayTime)
                    end)
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

    --计算停轮时的轮盘
    local endIndex
    for i=1, #self.m_wheelConfig do
        if self.m_wheelResult[2] == self.m_wheelConfig[i] then
            endIndex = i
            break
        end
    end
    local lastList = {}
    --第3个为中间的点,所以要从结束点开始向前取2个加在前面
    for index = 2,1,-1 do
        local symbolIndex = endIndex - index
        if symbolIndex < 1 then
            symbolIndex = symbolIndex + #self.m_wheelConfig
        end
        local symbolType = self.m_wheelConfig[symbolIndex]
        lastList[#lastList + 1] = symbolType
    end
    for index = 1,#self.m_wheelConfig - 2 do
        local symbolType = self.m_wheelConfig[endIndex + index - 1]
        lastList[#lastList + 1] = symbolType
    end

    reelNode:setSymbolList(lastList)

    return reelNode
end

function LuxeVegasSmallWheelView:createWheelNode(symbolType)
    local symbolNode = util_createAnimation("LuxeVegas_BonusWheel_Item.csb")
    local rewardNode = symbolNode:findChild("Node_mul_"..symbolType)
    if self.m_machine.m_gamePlayMul == self.m_machine.M_ENUM_TYPE.FREE_2 and symbolType == 25 then
        rewardNode = symbolNode:findChild("Node_high_mul_"..symbolType)
    end
    
    if rewardNode then
        rewardNode:setVisible(true)
    end
    return symbolNode
end

return LuxeVegasSmallWheelView
