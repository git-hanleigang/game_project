---
--smy
--2018年4月18日
--JackpotOGoldWheelView.lua


local JackpotOGoldWheelView = class("JackpotOGoldWheelView", util_require("Levels.BaseLevelDialog"))
JackpotOGoldWheelView.m_randWheelIndex = nil
JackpotOGoldWheelView.m_wheelSumIndex =  18 -- 轮盘有多少块
JackpotOGoldWheelView.m_wheelData = {} -- 大轮盘信息
JackpotOGoldWheelView.m_wheelNode = {} -- 大轮盘Node 
JackpotOGoldWheelView.m_wheelEffectNode = {} -- 大轮盘Node effect
JackpotOGoldWheelView.m_wheelSmallNode = {} -- 小轮盘成倍Node 
JackpotOGoldWheelView.m_bIsTouch = nil
JackpotOGoldWheelView.m_chengbeiIndex = 1 --当前成倍ID
JackpotOGoldWheelView.m_wheelGunIndex = 0 --当前是转动的第几轮
JackpotOGoldWheelView.m_wheelCurWin = 0 --当前赢钱
JackpotOGoldWheelView.m_callBackFun = nil --轮盘流程结束之后  的 回调

function JackpotOGoldWheelView:initUI(machine)
    
    self.m_machine = machine

    self:createCsbNode("JackpotOGold_Wheel.csb") 

    self:changeBtnEnabled(false)

    self.m_bIsTouch = true
    self.m_wheel = require("CodeJackpotOGoldSrc.JackpotOGoldWheelAction"):create(self:findChild("Node_zhuan"),self.m_wheelSumIndex,function()
        -- 滚动结束调用
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
    self:addChild(self.m_wheel)

    -- 添加5种乘倍
    for i=1,5 do
        self.m_wheelSmallNode[i] = util_createAnimation("JackpotOGold_Wheel_Multi_"..i..".csb")
        self:findChild("Node_Multi_"..i):addChild(self.m_wheelSmallNode[i])
    end

    -- 添加18个node
    for i=1,18 do
        self.m_wheelNode[i] = {}
        for j=1,5 do
            local smallNode = util_createAnimation("JackpotOGold_Wheel_"..j..".csb")
            self:findChild("Node_"..i):addChild(smallNode)
            self.m_wheelNode[i][j] = smallNode
        end
        self.m_wheelEffectNode[i] = util_createAnimation("JackpotOGold_Wheel_effect.csb")
        self:findChild("Node_Effect_"..i):addChild(self.m_wheelEffectNode[i])
        self.m_wheelEffectNode[i]:setVisible(false)
    end

    -- 中奖特效
    self.m_zhongjiangEffect = util_createAnimation("JackpotOGold_Wheel_zhongjiang.csb")
    self:findChild("kuangzhongjiang"):addChild(self.m_zhongjiangEffect)
    self.m_zhongjiangEffect:setVisible(false)

    -- 再来一次弹板
    self.m_againEffect = util_createAnimation("JackpotOGold_Again.csb")
    self:findChild("Node_again"):addChild(self.m_againEffect)
    self.m_againEffect:setVisible(false)

    -- 赢钱框
    self.m_WheelTotalWin = util_createAnimation("JackpotOGold_Wheel_TotalWin.csb")
    self:findChild("Node_TotalWin"):addChild(self.m_WheelTotalWin)
    -- self.m_WheelTotalWin:setZOrder(10)

    -- 赢钱飞的彩虹
    self.m_winCaiHong = util_createAnimation("JackpotOGold_Jackpot_shouji_0.csb")
    self:findChild("Node_shouji_0"):addChild(self.m_winCaiHong)
    self.m_winCaiHong:setVisible(false)

    self.m_winWheelEffect = util_createAnimation("JackpotOGold_Wheel_effect.csb")
    self:findChild("Node"):addChild(self.m_winWheelEffect)
    self.m_winWheelEffect:setVisible(false)

    self.m_Wheel_maozi_down = util_spineCreate("JackpotOGold_Wheel_maozi_down", true, true)
    self:findChild("guadian"):addChild(self.m_Wheel_maozi_down)
    self:findChild("guadian"):setZOrder(1)

    self.m_Wheel_maozi_up = util_spineCreate("JackpotOGold_Wheel_maozi_up", true, true)
    self:findChild("guandian_up"):addChild(self.m_Wheel_maozi_up)
    self:findChild("guandian_up"):setZOrder(4)

    self:findChild("Node"):setZOrder(3)

    self:setWheelRotModel()

    self.m_randWheelIndex = 1 -- 设置轮盘滚动位置

     self:initCallBack()
    -- 点击layer
    -- self:setTouchLayer()

    self:findChild("Node_TotalWin"):setZOrder(2)
    self:findChild("Node_again"):setZOrder(11)
end

-- 刷新轮盘界面
function JackpotOGoldWheelView:updateWheelView(collectcredit, isshow, _func)
    if not collectcredit then
        return
    end
    if _func then
        self.m_callBackFun = _func
    end

    for wheelIndex = 1, 18 do
        for index = 1, 5 do
            self.m_wheelNode[wheelIndex][index]:setVisible(false)
        end
    end
    self.m_wheelNodeNew = {}
    for wheelIndex , v in ipairs(collectcredit) do
        self.m_wheelNode[wheelIndex][self:getJackpotId(v[1])]:setVisible(true)
        if isshow then
            if wheelIndex == #collectcredit then
                self.m_wheelNode[wheelIndex][self:getJackpotId(v[1])]:setVisible(false)
            end
        end
        
        self.m_wheelNodeNew[wheelIndex] = self.m_wheelNode[wheelIndex][self:getJackpotId(v[1])]
        for index = 1, 5 do
            self.m_wheelNode[wheelIndex][index]:findChild("m_lb_coins"):setString(util_formatCoinsLN(v[2],3))
            self.m_wheelNode[wheelIndex][index]:findChild("m_lb_coins_0"):setString(util_formatCoinsLN(v[2],3))
        end
    end
end

-- 刷新最新获得jackpot
function JackpotOGoldWheelView:updateNewJackpotWheelView(index,collectcredit,_func)
    if not collectcredit then
        return
    end

    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_update_gezi.mp3")

    self.m_wheelNode[index][self:getJackpotId(collectcredit[1])]:runCsbAction("actionframe1",false,function (  )
        if _func then
            _func()
        end
    end)
    for i=1,5 do
        self.m_wheelEffectNode[index]:findChild("Node_"..i):setVisible(false)
    end
    self.m_wheelEffectNode[index]:findChild("Node_"..self:getJackpotId(collectcredit[1])):setVisible(true)

    self.m_wheelNode[index][self:getJackpotId(collectcredit[1])]:setVisible(true)
    self.m_wheelNode[index][self:getJackpotId(collectcredit[1])]:runCsbAction("actionframe1",false,function (  )
        
    end)

    self.m_wheelEffectNode[index]:setVisible(true)
    self.m_wheelEffectNode[index]:runCsbAction("actionframe",false,function (  )
        self.m_wheelEffectNode[index]:setVisible(false)
    end)
    
end

-- 区分5种jackpot
function JackpotOGoldWheelView:getJackpotId(jackpotName)
    if jackpotName == "grand" then
        return 1
    elseif jackpotName == "super" then
        return 2
    elseif jackpotName == "major" then
        return 3
    elseif jackpotName == "minor" then
        return 4
    elseif jackpotName == "mini" then
        return 5
    end
end

-- 轮盘18个node 一次扫光
function JackpotOGoldWheelView:playGuangEffectNode(collectcredit)
    for i=1,18 do
        self:waitWithDelay(nil, function (  )
            self.m_wheelNode[i][self:getJackpotId(collectcredit[i][1])]:runCsbAction("actionframe",false,function()
                -- if i == 18 then
                --     self.m_wheelSmallNode[1]:runCsbAction("actionframe",false,function()
                --         self:beginWheelAction()
                --     end)
                -- end
            end)
        end, 3/60*(i-1))
    end
    self.m_wheelGunIndex = 0
end

function JackpotOGoldWheelView:clickFunc(_sender)
    
    if self:isVisible() == false then
        return
    end

    if self.m_machine.m_isWheelReturnClick then
        return
    end

    if _sender then
        local name = _sender:getName()
        if name == "Btn_return" then-- 返回
            self.m_machine.m_isWheelReturnClick = true
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_return_click.mp3")

            self.m_machine:clickCloseWheelView()
            return
        end
    end

end

-- 转盘转动结束调用
function JackpotOGoldWheelView:initCallBack()
    self.m_callFunc = function()
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_run_end.mp3")

        self.m_bIsTouch = true
        self.m_zhongjiangEffect:setVisible(true)
        self.m_zhongjiangEffect:runCsbAction("actionframe",false,function()
            self.m_zhongjiangEffect:setVisible(false)
            self:runFlyGold(function()
                self:beginWheelAction()
            end)
        end)
    end
end

-- 中奖之后 钱数收集飞
function JackpotOGoldWheelView:runFlyGold(_func)
    self:findChild("Node_Multi_1")
    -- self.m_winCaiHong:setVisible(false)

    local collectwin = self.m_machine.m_runSpinResultData.p_selfMakeData.collectwin
    -- self.m_wheelSmallNode[collectwin[self.m_wheelGunIndex-1][1]]:runCsbAction("start_dark",false)

    local startWorldPos =  self.m_wheelSmallNode[collectwin[self.m_wheelGunIndex][1]]:findChild("Node_3"):getParent():convertToWorldSpace(cc.p(self.m_wheelSmallNode[collectwin[self.m_wheelGunIndex][1]]:findChild("Node_3"):getPosition()))
    local startPos = self:convertToNodeSpace(startWorldPos)
    
    local endPosWord = self:findChild("kuangzhongjiang"):getParent():convertToWorldSpace(cc.p(self:findChild("kuangzhongjiang"):getPosition()))
    local endPos = self:convertToNodeSpace(endPosWord)

    local endPosWord1 = self.m_WheelTotalWin:findChild("m_lb_coins"):getParent():convertToWorldSpace(cc.p(self.m_WheelTotalWin:findChild("m_lb_coins"):getPosition()))
    local endPos1 = self:convertToNodeSpace(endPosWord1)

    -- 创建粒子
    local flyNode =  util_createAnimation("JackpotOGold_Wheel_Multi_shouji.csb")
    self:addChild(flyNode,300000)
    for i=1,5 do
        flyNode:findChild("JackpotOGold_zp_"..i):setVisible(false)
    end
    flyNode:findChild("Node_68"):setVisible(false)
    flyNode:findChild("JackpotOGold_zp_"..collectwin[self.m_wheelGunIndex][1]):setVisible(true)

    flyNode:setPosition(cc.p(startPos))

    if flyNode:findChild("Particle_1") then
        flyNode:findChild("Particle_1"):setDuration(1000)
        flyNode:findChild("Particle_1"):setPositionType(0)
        flyNode:findChild("Particle_1"):resetSystem()
    end
    if flyNode:findChild("Particle_1_0") then
        flyNode:findChild("Particle_1_0"):setDuration(1000)
        flyNode:findChild("Particle_1_0"):setPositionType(0)
        flyNode:findChild("Particle_1_0"):resetSystem()
    end

    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_chengbei_collect.mp3")

    flyNode:runCsbAction("shouji",false)
    self:waitWithDelay(nil, function()
        local move = cc.MoveTo:create(15/60,endPos)
        local call = cc.CallFunc:create(function ()
            for i=1,5 do
                flyNode:findChild("JackpotOGold_zp_"..i):setVisible(false)
            end

            self.m_winWheelEffect:setVisible(true)
            self.m_winWheelEffect:runCsbAction("actionframe2",false,function()
                self.m_winCaiHong:setVisible(true)
                self.m_winCaiHong:runCsbAction("auto",false,function()
                    if _func then
                        _func()
                    end
                end)

                flyNode:findChild("Node_68"):setVisible(true)
                flyNode:findChild("m_lb_coins"):setString(util_formatCoins(collectwin[self.m_wheelGunIndex][5], 3))

                local move1 = cc.MoveTo:create(15/60,endPos1)
                local call1 = cc.CallFunc:create(function ()
                    if flyNode:findChild("Particle_1") then
                        flyNode:findChild("Particle_1"):stopSystem()
                    end
                    if flyNode:findChild("Particle_1_0") then
                        flyNode:findChild("Particle_1_0"):stopSystem()
                    end

                    self.m_wheelCurWin = self.m_wheelCurWin + collectwin[self.m_wheelGunIndex][5]
                    self.m_WheelTotalWin:findChild("m_lb_coins"):setString(util_formatCoins(self.m_wheelCurWin, 30))
                    local node=self.m_WheelTotalWin:findChild("m_lb_coins")
                    self.m_WheelTotalWin:updateLabelSize({label=node,sx=1,sy=1},465)
                    self.m_WheelTotalWin:runCsbAction("actionframe",false)
                    gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_chengbei_collect_feedback.mp3")

                    flyNode:findChild("Node_68"):setVisible(false)

                    self:waitWithDelay(nil, function()
                        flyNode:removeFromParent()
                    end,0.5)
                end)

                local seq = cc.Sequence:create(move1,call1)
                flyNode:runAction(seq)
                flyNode:runCsbAction("shouji1",false,function()
                    
                end)
            end)
        end)

        local seq = cc.Sequence:create(move,call)
        flyNode:runAction(seq)
    end,0.5)
    
end

function JackpotOGoldWheelView:onEnter()
    JackpotOGoldWheelView.super.onEnter(self)
end

function JackpotOGoldWheelView:onExit()
   JackpotOGoldWheelView.super.onExit(self) 
end

function JackpotOGoldWheelView:changeBtnEnabled( isCanTouch)
    -- self.m_csbOwner("JackpotOGold_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end

-- 设置转盘盘滚动参数
function JackpotOGoldWheelView:beginWheelAction()
    self.m_wheelGunIndex = self.m_wheelGunIndex + 1
    local collectwin = self.m_machine.m_runSpinResultData.p_selfMakeData.collectwin
    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_callFunc
    if self.m_wheelGunIndex <= #collectwin then 
        self.m_randWheelIndex = collectwin[self.m_wheelGunIndex][3]
        self.m_chengbeiIndex = collectwin[self.m_wheelGunIndex][1]
    end

    self.distance_pre = 0
    self.distance_now = 0
    if self.m_wheelGunIndex ~= 1 then
        -- 数据走完了 结算
        if self.m_wheelGunIndex > #collectwin then
            if self.m_wheelNodeNew[collectwin[self.m_wheelGunIndex-1][3]] then
                self.m_wheelNodeNew[collectwin[self.m_wheelGunIndex-1][3]]:runCsbAction("dark",false)
            end
            self.m_wheelSmallNode[5]:runCsbAction("start_dark",false)
            self:waitWithDelay(nil, function (  )
                self.m_machine:updateBottomCoin(self.m_wheelCurWin)

                -- 播弹板音效时 停掉背景音
                gLobalSoundManager:setBackgroundMusicVolume(0)
                gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_tanban.mp3")

                self.m_machine:showWheelOverView(self.m_callBackFun, self.m_wheelCurWin)
            end, 0.5) 
            
            return
        end

        -- 转过的 压暗
        -- for i=1,5 do
        --     self.m_wheelNode[collectwin[self.m_wheelGunIndex-1][3]][i]:runCsbAction("dark",false)
        -- end
        self.m_wheelNodeNew[collectwin[self.m_wheelGunIndex-1][3]]:runCsbAction("dark",false)
        
        -- 判断是否是否需要新转动 倍数
        if collectwin[self.m_wheelGunIndex][1] ~= collectwin[self.m_wheelGunIndex-1][1] then
            -- 转过的 成倍 压暗 
            self.m_wheelSmallNode[collectwin[self.m_wheelGunIndex-1][1]]:runCsbAction("start_dark",false)
            
            -- 成倍逆时针 转动
            local move = cc.RotateTo:create(0.5, -72*(self.m_chengbeiIndex-1))
            self:findChild("Node_Multi_zhuan"):runAction(move)
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_chengbei_xuanzhuan.mp3")

            self:waitWithDelay(nil, function (  )
                self.m_wheel:changeWheelRunData(wheelData)

                self.m_wheel:beginWheel()
                -- 设置轮盘功能滚动结束停止位置
                self.m_wheel:recvData(self.m_randWheelIndex)
            end, 0.5)
        else
            gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_again_tanban.mp3")
            self.m_againEffect:setVisible(true)
            self.m_againEffect:runCsbAction("auto",false,function()
                self.m_againEffect:setVisible(false)
                self.m_wheel:changeWheelRunData(wheelData)

                self.m_wheel:beginWheel()
                -- 设置轮盘功能滚动结束停止位置
                self.m_wheel:recvData(self.m_randWheelIndex)
            end)
        end
    else
        self.m_wheel:changeWheelRunData(wheelData)

        self.m_wheel:beginWheel()
        -- 设置轮盘功能滚动结束停止位置
        self.m_wheel:recvData(self.m_randWheelIndex)
    end

end

-- 返回上轮轮盘的停止位置
function JackpotOGoldWheelView:getLastEndIndex( )
   return self.m_randWheelIndex
    
end

-- 设置轮盘实时滚动调用
function JackpotOGoldWheelView:setWheelRotModel( )
   
    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function JackpotOGoldWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 
        
        gLobalSoundManager:playSound("JackpotOGoldSounds/sound_JackpotOGold_wheel_rptate.mp3")       
    end
end

-- 延时函数
function JackpotOGoldWheelView:waitWithDelay(parent, endFunc, time)
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        
        waitNode:removeFromParent()
        waitNode = nil
    end, time)
end

-- 重置转轮为初始状态
function JackpotOGoldWheelView:resetWheelView( )
    self:findChild("Node_zhuan"):setRotation(0)
    self:findChild("Node_Multi_zhuan"):setRotation(0)
    self.m_wheel.m_currentDistance = 0
    self.m_wheelCurWin = 0
    for i=1,5 do
        self.m_wheelSmallNode[i]:runCsbAction("idle",false)
    end
end

return JackpotOGoldWheelView