--[[
    免费轮盘飞行翻倍label

    shouji  0-37帧    对应VIP弹窗上的乘倍数字位移飞向转盘按钮
    0-8帧为原地缩放，8-37帧飞入转盘按钮，速度曲线为加速曲线  在第35帧至37帧区间播放转盘界面的show2时间线，同时切换为idle时间线，固定在转盘按钮上。
]]
local DailybonusMultipLabel = class("DailybonusMultipLabel", util_require("base.BaseView"))
DailybonusMultipLabel.m_nowMulitip = nil

function DailybonusMultipLabel:initUI()
    self:createCsbNode("Hourbonus_new3/DailybonusMulitipLabel.csb")

    local boostVipLv = nil
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        boostVipLv = vipBoost:getBoostVipLevel()
    end

    local vipLevel = globalData.userRunData.vipLevel
    if boostVipLv then
        vipLevel = vipLevel + boostVipLv
    end

    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local vipNum = 1
    local levelInfo = vipData:getVipLevelInfo(vipLevel)
    if levelInfo then
        vipNum = levelInfo.cashBonus
    end
    -- for i = 1, VipConfig.MAX_LEVEL do
    --     local levelInfo = vipData:getVipLevelInfo(i)

    --     if i == vipLevel then
    --         vipNum = levelInfo.cashBonus
    --     end
    -- end

    self.m_nowMulitip = vipNum
    self:setMultipNum(self.m_nowMulitip)
end

--世界坐标 endPos   playShow2Func播放轮盘show2动画回调
function DailybonusMultipLabel:playFlyAction(endPos, playShow2Func)
    local playBezierAction = function()
        -- local startPos = cc.p(self:getPosition())
        -- local radian = 75*math.pi/180
        -- local height = endPos.y - self:getPositionY()
        -- local q1x = startPos.x+(endPos.x - startPos.x)/4
        -- local q1 = cc.p(q1x, height + startPos.y+math.cos(radian)*q1x)
        -- local bez=cc.BezierTo:create(0.8,{q1,endPos,endPos})
        -- self:runAction(cc.Sequence:create(cc.DelayTime:create(0.5),cc.EaseIn:create(bez, 2) ,nil))

        --走直线
        local speed = 220
        local startPos = cc.p(self:getPosition())
        local dis = ccpDistance(startPos, endPos)
        local moveAction = cc.MoveTo:create(0.8, endPos)
        self:runAction(cc.Sequence:create(cc.MoveBy:create(0.1, cc.p(0, 20)), cc.DelayTime:create(0.4), cc.EaseIn:create(moveAction, 2), nil))
    end

    self:runCsbAction(
        "shouji",
        false,
        function()
            playShow2Func()
        end
    )
    playBezierAction()

    --     --vip板子上放大缩小
    --    util_csbPlayForIndex(self.m_csbAct,0,8,false,function(  )

    --     util_csbPlayForIndex(self.m_csbAct,8,35,false,function(  )
    --        -- 飞向spin按钮
    --        playBezierAction()
    --         --继续播放
    --         util_csbPlayForIndex(self.m_csbAct,35,37,false,function(  )
    --              --调用主轮盘show2回调
    --              playShow2Func()
    --         end)
    --     end)

    --    end)
end

--闪电击中
function DailybonusMultipLabel:playLightHitAction()
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusLabelMulitipX.mp3")
    self.m_nowMulitip = self.m_nowMulitip * G_GetMgr(G_REF.CashBonus):getMultipleData().p_value
    self:setMultipNum(self.m_nowMulitip)
    self:runCsbAction("start2", false)
end

function DailybonusMultipLabel:setMultipNum(num)
    self:findChild("LabelMulitip"):setString("X" .. num)
end

--闪电击中后翻倍动画
function DailybonusMultipLabel:playMulitpXAction()
    self:runCsbAction("switch", false)
end

--付费轮盘砸入轮盘动画
function DailybonusMultipLabel:playbuyWheelMulitpXAction(funcEND)
    self:runCsbAction(
        "switch2",
        false,
        function()
            funcEND()
        end
    )
end
return DailybonusMultipLabel
