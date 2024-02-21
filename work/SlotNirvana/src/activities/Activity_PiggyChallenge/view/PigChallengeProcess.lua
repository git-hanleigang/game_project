-- 小猪挑战进度条控件

local RewardBox = require("activities.Activity_PiggyChallenge.view.PigChallengeBox")
local PigChallengeProcess = class("PigChallengeProcess", BaseView)

function PigChallengeProcess:ctor()
    self.m_config = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getConfig()
    self.m_data = G_GetMgr(ACTIVITY_REF.PiggyChallenge):getRunningData()
    PigChallengeProcess.super.ctor(self)
end

function PigChallengeProcess:initUI()
    PigChallengeProcess.super.initUI(self)

    -- 创建宝箱
    for boxId, node in pairs(self.box_nodes) do
        local reward_data = self.m_data:getRewardDataByBoxId(boxId)
        local rewardBox = util_createView("activities.Activity_PiggyChallenge.view.PigChallengeBox", boxId, reward_data, "process")
        node:addChild(rewardBox)
    end

    -- 显示刻度
    local isSmallR = self.m_data:isSmallR()
    self.spDial_s:setVisible(isSmallR)
    self.spDial_b:setVisible(not isSmallR)

    -- 显示档位
    for idx, lb_gear in ipairs(self.lb_gears) do
        local gearIdx = isSmallR and idx or idx * 2
        lb_gear:setString(gearIdx)
    end

    local cur_process = self.m_data:getCurProcess()
    self.sp_process:setPercent(math.floor(cur_process * 100))

    -- 添加点击事件
    local layout = ccui.Layout:create()
    layout:setName("layout_goPiggy")
    layout:setTouchEnabled(true)

    local process_size = self.sp_process:getContentSize()
    local scaleX = self.sp_process:getScaleX()
    local scaleY = self.sp_process:getScaleY()
    layout:setContentSize(cc.size(process_size.width * scaleX, process_size.height * scaleY))
    layout:addTo(self.sp_process)
    self:addClick(layout)
end

function PigChallengeProcess:initCsbNodes()
    self.sp_process = self:findChild("progress")
    self.panel_eff = self:findChild("panel_eff")

    self.spDial_b = self:findChild("sp_kedu") --大R的
    self.spDial_s = self:findChild("sp_kedu2") --小R的

    self.box_nodes = {}
    self.lb_gears = {}
    for idx = 1, 4 do
        local node_box = self:findChild("node_" .. idx)
        table.insert(self.box_nodes, idx, node_box)

        local lb_gear = self:findChild("lb_" .. idx)
        table.insert(self.lb_gears, idx, lb_gear)
    end
end

function PigChallengeProcess:getCsbName()
    return self.m_config.BankProgress
end

-- 宝箱闪烁效果
function PigChallengeProcess:playBoxEffect()
    local cur_idx = self.m_data:getCurIdx()
    -- 修正值
    if self.record_idx >= table.nums(self.reward_items) then
        self.record_idx = cur_idx
    end
    for idx, reward_item in ipairs(self.reward_items) do
        if idx > self.record_idx and not self.m_data:isRewardCollected(idx) then
            if reward_item then
                reward_item:runCsbAction(
                    "idle",
                    false,
                    function()
                        self:playBoxEffect()
                    end
                )
                self.record_idx = idx
                break
            end
        end
    end
end

-- 统一点击回调
function PigChallengeProcess:clickFunc(sender)
    local name = sender:getName()

    if name == "layout_goPiggy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeMainUI()
    end
end

-- TODO 关闭小猪界面
function PigChallengeProcess:closeMainUI()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIG_CHALLENGE_PROCESS_CLICKED)
end

function PigChallengeProcess:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                if params and params.init_type == "process" then
                    self:closeMainUI()
                end
            end
        end,
        ViewEventType.NOTIFY_PIG_CHALLENGE_REWARD_CLICKED
    )
end

function PigChallengeProcess:setParticleVisible(bl_visible)
    if type(bl_visible) == "boolean" then
        if not tolua.isnull(self.panel_eff) then
            self.panel_eff:setVisible(bl_visible)
        end
    end
end

return PigChallengeProcess
