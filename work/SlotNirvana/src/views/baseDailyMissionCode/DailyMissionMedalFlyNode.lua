--[[
    --新版每日任务pass主界面 积分飞行节点
    csc 2021-07-02
]]
local DailyMissionMedalFlyNode = class("DailyMissionMedalFlyNode", util_require("base.BaseView"))
function DailyMissionMedalFlyNode:initUI(_data)
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_labMealNum   = self:findChild("lb_medal")
    self.m_labMealNum:setString(_data)
    local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
    if data then
        local isBuyMonthlyCardNormal = data:isBuyMonthlyCardNormal()
        if isBuyMonthlyCardNormal then --购买了普通版月卡
            self.m_labMealNum:setColor(cc.c3b(76, 255, 0))
        end
    end

    self.m_particle = self:findChild("Particle_1")
    self.m_particle:stopSystem()-- 默认停掉粒子
end

function DailyMissionMedalFlyNode:getCsbName()
    return DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_MedalFlyNode.csb"
end

-- 播放飞行动画衔接
function DailyMissionMedalFlyNode:playFlyAction(_startPos,_endPos,_callback)
    local mp3Path = DAILYPASS_RES_PATH.PASS_FLYNODE_ACTION_MP3
    gLobalSoundManager:playSound(mp3Path)
    self:runCsbAction(
        "start",
        false,
        function()
            -- 设置粒子效果拖尾
            --创建运行轨迹

            local bezier = self:getBezier(_startPos, _endPos)
            -- actionList[#actionList + 1] = cc.BezierTo:create(0.3, bezier)
            local act = cc.BezierTo:create(0.7, bezier)
            self:runAction(act)
            self.m_particle:setPositionType(0)
            self.m_particle:setDuration(1)
            self.m_particle:resetSystem()
            self:runCsbAction(
                "fly",
                false,
                function()
                    self:runCsbAction(
                        "over",
                        false,
                        function()
                            -- 刷新任务
                            if _callback then
                                _callback()
                            end
                            self:removeFromParent()
                        end,
                        60
                    )
                end,
                60
            )
        end,
        60
    )

end

--贝塞尔曲线计算
function DailyMissionMedalFlyNode:getBezier(pos, endPos)
    local bezier = {}
    bezier[1] = cc.p(pos.x, pos.y)
    bezier[2] = cc.p(pos.x - 200, pos.y + 300)
    bezier[3] = endPos
    return bezier
end

return DailyMissionMedalFlyNode