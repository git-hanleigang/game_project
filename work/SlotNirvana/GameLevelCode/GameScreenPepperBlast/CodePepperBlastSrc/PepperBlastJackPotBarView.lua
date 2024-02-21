---
--xcyy
--2018年5月23日
--PepperBlastJackPotBarView.lua

local PepperBlastJackPotBarView = class("PepperBlastJackPotBarView", util_require("base.BaseView"))
--辣椒展示类型
PepperBlastJackPotBarView.m_lajiaoShowType = 1
--第一个奖金池的收集数量
local FirstLevelCollectNum = 15

function PepperBlastJackPotBarView:initUI()
    self:createCsbNode("JackPotBarPepperBlast.csb")
    -- 一些状态
    self.m_isReSpin = false --reSpin模式
    self.m_isPlayIdleAction = false --正在播放所有idle动画
    -- 奖金倍率
    self.m_winMultiple = 1
    --当前reSpin模式收集等阶对应的收集数量
    self.m_reSpinCollectNum = 0
    --文本尺寸适配参数
    self.m_labelNodes = {}
    self.m_labelWidth = {}
    self.m_labelScale = {}
    --其他挂载的csb
    self.m_huoqius = {}       --升阶动效的火球
    self.m_lajiaos = {}       --各个等阶的辣椒
    --阶数对应收集数量
    self.m_levels = {}

    local node = {}
    local width = 0
    local scale = 1
    for _index = FirstLevelCollectNum, 1, -1 do
        node = self:findChild("BitmapFontLabel_" .. _index)
        if (node) then
            width = node:getContentSize().width
            scale = node:getScale()
            --存一下工程内的尺寸缩放 以此为标准
            table.insert(self.m_labelNodes, node)
            table.insert(self.m_labelWidth, width)
            table.insert(self.m_labelScale, scale)
            --存一下 收集等阶 对应 收集数量
            table.insert(self.m_levels, _index)
            --添加辣椒csb
            local lajiaoNode = util_createAnimation("PepperBlastJackpot_LaJiao.csb")
            local lajiaoParent = self:findChild("lajiao_" .. _index)
            lajiaoParent:addChild(lajiaoNode)
            --初始化创建时直接设置可见性
            lajiaoNode:findChild("Node_2"):setVisible(true)
            lajiaoNode:findChild("Node_1"):setVisible(false)
            table.insert(self.m_lajiaos, lajiaoNode)
        else
            break
        end
    end
end

function PepperBlastJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PepperBlastJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function PepperBlastJackPotBarView:onExit()
end

-- 更新jackpot 数值信息
--
function PepperBlastJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    local data = self.m_csbOwner

    for _index, _node in ipairs(self.m_labelNodes) do
        self:changeNode(_node, _index)
        self:updateLabelSize({label = _node, sx = self.m_labelScale[_index], sy = self.m_labelScale[_index]}, self.m_labelWidth[_index])
    end
end

function PepperBlastJackPotBarView:changeNode(label, index)
    local value = self.m_machine:BaseMania_updateJackpotScore(index) * self.m_winMultiple
    if value > 0 then
        label:setString(util_formatCoins(value, 20, nil, nil, true))
    end
end

--普通模式下idle动画
function PepperBlastJackPotBarView:setCurReSpinState(sReSpin)
    self.m_isReSpin = sReSpin
end
function PepperBlastJackPotBarView:playJackPotBarAllIdleAction(index)
    if (self.m_isReSpin) then
        self.m_isPlayIdleAction = false
        return
    end
    --正在执行递归时 其他接口调用不理会
    if(self.m_isPlayIdleAction)then
        return
    end

    self.m_isPlayIdleAction = true

    if (not index or not self.m_levels[index]) then
        index = 1
    end
    local actName = string.format("idle%d", index)
    --jackPot栏 亮
    self:runCsbAction(
        actName,
        false,
        function()
            local waitNode = cc.Node:create()
            self:addChild(waitNode)

            performWithDelay(
                waitNode,
                function()
                    self.m_isPlayIdleAction = false
                    self:playJackPotBarAllIdleAction(index + 1)
                    waitNode:removeFromParent()
                end,
                1
            )
        end
    )
    --对应辣椒
    local lajiao = self.m_lajiaos[index]
    lajiao:runCsbAction("idle", false)
end

function PepperBlastJackPotBarView:setJackPotDiVisibleByCollectNum(sLightIndex, eLightIndex)
    sLightIndex = sLightIndex or 7
    eLightIndex = eLightIndex or 15

    local jackpot_di = {}
    local isVis = false
    for _index = 7, 15 do
        jackpot_di = self:findChild(string.format("jackpot_di_%d_0", _index))
        isVis = (sLightIndex <= _index and _index <= eLightIndex)
        jackpot_di:setVisible(isVis)

        --对应辣椒
        if (not isVis) then
            local jackPot_index = self:getCollectLevelByNum(_index)
            local lajiao = self.m_lajiaos[jackPot_index]
            lajiao:pauseForIndex(0)
        end
    end
end
--========================reSpin模式下接口
function PepperBlastJackPotBarView:setWinMultiple(winMultiple)
    if(not winMultiple)then
        --为nil 的话取一下 服务器数据初始化 红辣椒 触发reSPin模式 1.25倍
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
        winMultiple = selfData and tonumber(selfData.winMultiple) or 1
    end
    self.m_winMultiple = winMultiple
end

-- @showType 1:普通模式 2:带火的辣椒
function PepperBlastJackPotBarView:upDateLajiaoShow(showType)
    self.m_lajiaoShowType = showType
    --普通模式不用播动效
    if(1 == self.m_lajiaoShowType)then
        for _index,_lajiao in ipairs(self.m_lajiaos) do
            _lajiao:findChild("Node_2"):setVisible(1 == showType)
            _lajiao:findChild("Node_1"):setVisible(2 == showType)
        end
        return
    end

    --第10帧切换
    local actName = "switch"
    local time = 10 / 60

    local lastIndex = #self.m_lajiaos
    for _index=lastIndex,1,-1 do
        local lajiao = self.m_lajiaos[_index]
        --延迟0.1s 间断播放
        local delayTime = (lastIndex - _index) * 0.1
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(
            delayNode,
            function()
                lajiao:runCsbAction(actName, false)

                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(
                    waitNode,
                    function()
                        lajiao:findChild("Node_2"):setVisible(1 == showType)
                        lajiao:findChild("Node_1"):setVisible(2 == showType)
                        waitNode:removeFromParent()
                    end,
                    time
                )

                delayNode:removeFromParent()
            end,
            delayTime
        )
    end
end
-- 触发了reSpin模式 记录一下reSpine的触发类型
function PepperBlastJackPotBarView:playTriggerReSpinAnim(isSpecialWild, isRespinReconnect, collectNum, endFun)
    --触发reSpin时设置奖金倍率
    self:setWinMultiple()
    --辣椒展示
    local showType = isSpecialWild and 2 or 1
    self:upDateLajiaoShow(showType)
    --触发时收集数量
    self.m_reSpinCollectNum = collectNum
    --特殊wild触发时 播动画
    if (isSpecialWild and not isRespinReconnect) then
        --普通wild触发时
        local actName = "actionframe_l"
        self:runCsbAction(
            actName,
            false,
            function()
                local jackPot_index = self:getCollectLevelByNum(self.m_reSpinCollectNum)
                self:playLightAnim(jackPot_index, true)

                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(
                    waitNode,
                    function()
                        endFun()
                        waitNode:removeFromParent()
                    end,
                    0.5
                )
            end
        )
    else
        --隐藏其他地板
        self:setJackPotDiVisibleByCollectNum(self.m_reSpinCollectNum, self.m_reSpinCollectNum)
        local actName = "actionframe_n"
        self:runCsbAction(
            actName,
            false,
            function()
                local jackPot_index = self:getCollectLevelByNum(self.m_reSpinCollectNum)
                self:playLightAnim(jackPot_index, true)
                endFun()
            end
        )

        local jackPot_index = self:getCollectLevelByNum(self.m_reSpinCollectNum)
        local lajiao = self.m_lajiaos[jackPot_index]
        if (lajiao) then
            lajiao:runCsbAction("actionframe")
        end
    end
end

--reSpin模式下刷新收集数量
function PepperBlastJackPotBarView:updateReSpinCollectNum(collectNum)
    --重置
    if (nil == collectNum) then
        self.m_reSpinCollectNum = 7
        return
    end

    if (self.m_reSpinCollectNum ~= collectNum) then
        --暂停当前动效后 递归播放
        self:pauseForIndex(0)
        self:playReSpinUpGradeAction(self.m_reSpinCollectNum, collectNum)
    end
end
--reSpin模式下播放jackPot升阶特效
function PepperBlastJackPotBarView:playReSpinUpGradeAction(curCollectNum, endCollectNum)
    if (curCollectNum >= endCollectNum) then
        self.m_reSpinCollectNum = endCollectNum
        local jackPot_index = self:getCollectLevelByNum(self.m_reSpinCollectNum)

        --升阶最后 火球和闪光辣椒一起播放 
        --升阶音效
        gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Jackpot_UpGrade.mp3")
        local lajiao = self.m_lajiaos[jackPot_index]
        lajiao:runCsbAction("actionframe", true)
        self:playReSpinUpGradeActionHuoqiu(self.m_reSpinCollectNum, function()
            self:runCsbAction("actionframe_n", true)
        end)
        return
    end
    --隐藏不在范围内的特效节点
    self:setJackPotDiVisibleByCollectNum(curCollectNum, curCollectNum + 1)

    local actName = string.format("switch%dto%d", curCollectNum, curCollectNum + 1)
    self:runCsbAction(
        actName,
        false,
        function()
            self:playReSpinUpGradeAction(curCollectNum + 1, endCollectNum)
        end
    )

    local index = self:getCollectLevelByNum(curCollectNum)
    if (index > 0) then
        local lajiao = self.m_lajiaos[index]
        lajiao:runCsbAction("actionframe")
    end
end

--05.07移除火球展示
function PepperBlastJackPotBarView:playReSpinUpGradeActionHuoqiu(collectNum, endFun)
    --隐藏不在范围内的特效节点
    self:setJackPotDiVisibleByCollectNum(collectNum, collectNum)

    -- local huoqiu = self.m_huoqius[collectNum]
    -- --没有就创建
    -- if(not huoqiu)then
    --     local parent = self:findChild(string.format("JackPot_L%d", collectNum))
    --     huoqiu = util_createAnimation("JackPotBarPepperBlast_L.csb")
    --     parent:addChild(huoqiu)
    --     self.m_huoqius[collectNum] = huoqiu
    -- --有的话初始化一下展示
    -- else
    --     huoqiu:setVisible(true)
    -- end

    --火球 和 移动 一起播
    self:runCsbAction("actionframe_n", false, function(  )
        if(endFun)then
            endFun()
        end
    end)
    -- huoqiu:runCsbAction("actionframe", false, function()
    --     if(endFun)then
    --         endFun()
    --     end
    --     huoqiu:setVisible(false)
    -- end)
end

--reSpin模式下收集数量对应等阶获得奖金值
function PepperBlastJackPotBarView:getReSpinCollectScore()
    local local_score = 0
    local curLevel = self:getCollectLevelByNum()
    if (curLevel > 0) then
        local_score = self.m_machine:BaseMania_updateJackpotScore(curLevel) * self.m_winMultiple
    end

    local score = self.m_machine.m_runSpinResultData.p_resWinCoins or local_score
    return score
end
--reSpin结束 播放高亮展示 @isloop :是否高亮持续展示/
function PepperBlastJackPotBarView:playLightAnim(jackPot_index, isloop, endFun)
    local collectNum = self.m_levels[jackPot_index]
    if (not collectNum) then
        self:setJackPotDiVisibleByCollectNum(0, 0)
        return
    end
    self:setJackPotDiVisibleByCollectNum(collectNum, collectNum)

    local actName = isloop and "actionframe_n" or string.format("actionframe_s%d", collectNum)
    self:runCsbAction(
        actName,
        isloop,
        function()
            if (endFun) then
                endFun()
            end
        end
    )
    --对应辣椒
    local lajiao = self.m_lajiaos[jackPot_index]
    lajiao:runCsbAction("actionframe", isloop, function()
    end)
end

--获取奖金池索引 通过收集数量
function PepperBlastJackPotBarView:getCollectLevelByNum(collectNum)
    if (nil == collectNum) then
        collectNum = self.m_reSpinCollectNum
    end
    --阶数从小到大->收集数量从大到小
    for _level, _num in ipairs(self.m_levels) do
        if (collectNum >= _num) then
            return _level
        end
    end

    return 0
end

return PepperBlastJackPotBarView
