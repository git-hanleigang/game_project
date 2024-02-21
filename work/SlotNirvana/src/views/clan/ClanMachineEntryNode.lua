--[[
Author: cxc
Date: 2021-03-04 14:53:52
LastEditTime: 2021-07-22 17:43:35
LastEditors: Please set LastEditors
Description: 关卡内 公会入口
FilePath: /SlotNirvana/src/views/clan/ClanMachineEntryNode.lua
--]]
local ClanMachineEntryNode = class("ClanMachineEntryNode", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatManager = util_require("manager.System.ChatManager"):getInstance()

function ClanMachineEntryNode:initUI()
    local csbName = "Club/csd/GameSceneUiNode.csb"
    self:createCsbNode(csbName)

    self.curStep = 1
    self.m_curBetValue = 0 -- 当前关卡bet值

    self.m_nodeBoxUnlock = self:findChild("node_unlock")
    self.m_nodeBox = self:findChild("node_box")
    self.sp_logo = self:findChild("sp_logo")
    self.m_progBar = self:findChild("progress_close")
    self.m_lbProg = self:findChild("lb_progress_close")
    self.spRedDot = self:findChild("sp_num_close_bg")   -- 红点
    self.lb_num_close = self:findChild("lb_num_close")  -- 红点数字
    
    self:updateUI()

    -- 创建时检测下 公会信息(被别人同意加入公会或者踢了 刷新不及时)
    ClanManager:sendClanInfo()
end

function ClanMachineEntryNode:onEnter()
    ClanMachineEntryNode.super.onEnter(self)
    
    self.m_curBetValue = globalData.slotRunData:getCurTotalBet() -- 当前关卡bet值

    self:registerListener()
end

function ClanMachineEntryNode:updateUI()
    self:updateRedPoints()
    local clanData = ClanManager:getClanData()
    local nodeProg = self:findChild("node_prog")
    if not clanData:isClanMember() then
        nodeProg:setVisible(false)

        self.m_nodeBoxUnlock:setVisible(true)
        self.m_nodeBox:setVisible(false)
    else
        self.m_nodeBoxUnlock:setVisible(false)
        self.m_nodeBox:setVisible(true)

        nodeProg:setVisible(true)

        self:initProgUI()
    end

    ClanManager:setCurStep(self.curStep)

end

-- 入口 大小 (工具类会调用 排序 layout)
function ClanMachineEntryNode:getPanelSize()
    local nodePanelSize = self:findChild("Node_PanelSize")
    local size = nodePanelSize:getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size.height}
end

-- init 进度
function ClanMachineEntryNode:initProgUI()
    local prog = self:getPointsProg()
    self.m_progBar:setPercent(prog)
    self.m_lbProg:setString(prog .. "%")
    self.m_curProg = prog

    self:resetRewardBox()
end

function ClanMachineEntryNode:resetRewardBox(_cb)
    local clanData = ClanManager:getClanData()
    local taskData = clanData:getTaskData()
    
    for i=1, 6 do
        local spBox = self:findChild("gonghui_baoxiang" .. i)
        if spBox then
            spBox:setVisible(i == self.curStep)
        end
    end

    if _cb then
        _cb()
    end

end

-- 更新 进度
function ClanMachineEntryNode:updateProgUI(_bIgnoreStep)
    self:clearScheduler()

    if self.curStep == 6 then
        return
    end
    
    local prog = self:getPointsProg(not _bIgnoreStep)
    local tempProg = self.m_curProg or 0
    local step = 1
    self.m_schedule = schedule(self, function()
        tempProg = tempProg + math.floor(step)
        step = step + 0.3 
        if tempProg > prog then
            self.m_progBar:setPercent(prog)
            self.m_lbProg:setString(prog .. "%")
            self.m_curProg = prog
            self:clearScheduler()
            
            if prog >= 100 then
                local newStepProgAdd = function()
                    self.m_curProg = 0
                    self:updateProgUI(true)
                end
                self:resetRewardBox(newStepProgAdd)
            end
            
            return
        end
        
        self.m_progBar:setPercent(tempProg)
        self.m_lbProg:setString(tempProg .. "%")
    end, 0.2)

end

-- 获取 距离下一档位的进度
function ClanMachineEntryNode:getPointsProg(_bCheckStepUp)
    local clanData = ClanManager:getClanData()
    local taskData = clanData:getTaskData() -- 任务数据
    if not taskData then
        return 0
    end

    local curStep = self.curStep
    if taskData.curStep and self.curStep ~= taskData.curStep then
        curStep = taskData.curStep
    end
    if _bCheckStepUp and curStep > self.curStep then
        self.curStep = curStep
        return 100
    end

    self.curStep = curStep
    
    local prog = 0
    if taskData.totalStepEnergy > 0 and taskData.curStepEnergy > 0 then
        prog = math.floor(taskData.curStepEnergy / taskData.totalStepEnergy * 100)
    end

    return math.min(prog, 100)
end

-- 显示红点
function ClanMachineEntryNode:updateRedPoints()
    local clanData = ClanManager:getClanData()
    if not clanData:isClanMember() then
        self.spRedDot:setVisible( false )

        if self.timerAction then
            self:stopAction( self.timerAction )
            self.timerAction = nil
        end
        return
    end

    if not self.timerAction then
        self.timerAction = schedule(self,handler(self,self.updateRedPoints),1)
    end

    local num = ChatManager:getUnreadMessageCounts()
    if clanData:getUserIdentity() == ClanConfig.userIdentity.LEADER then
        num = num + clanData:getApplyCounts()
    end

    if num > 0 then
        if num > 99 then
            num = "99+"
        end
        self.spRedDot:setVisible( true )
        self.lb_num_close:setString( num )
        local rp_size = self.spRedDot:getContentSize()
        -- 底图是圆的 留15像素空余 文字才能完整显示在圆图里面
        self:updateLabelSize({label=self.lb_num_close},rp_size.width-15)
    else
        self.spRedDot:setVisible( false )
    end

end

function ClanMachineEntryNode:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_open" then

        self.m_bClick = true
        -- 显示 公会奖励界面
        ClanManager:sendClanInfo()
    end
end

function ClanMachineEntryNode:enterClanSystem()
    if not self.m_bClick then
        self:updateUI()
        return
    end
    self.m_bClick = false
    
    ClanManager:enterClanSystem()
end

-- 关卡内离开
function ClanMachineEntryNode:leaveClanSuccess()
    self:updateUI()
end

function ClanMachineEntryNode:clearScheduler(  )
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

function ClanMachineEntryNode:getFlyEndPos()
    local flyNode = self:findChild("node_flyEnd") or self

    return flyNode:convertToWorldSpace(cc.p(0,0))
end

-- 切换bet 事件
function ClanMachineEntryNode:changeBetValueEvt()
    local clanData = ClanManager:getClanData()
    if not clanData:isClanMember() then
        -- 没加入公会不用播放动画
        return
    end

    local newBetValue = globalData.slotRunData:getCurTotalBet() -- 当前关卡bet值
    if self.m_curBetValue == newBetValue then
        return
    end

    local csbName = "down"
    if newBetValue > self.m_curBetValue then
        csbName = "up"
    end
    self:runCsbAction(csbName)
    self.m_curBetValue = newBetValue
end

-- 注册事件
function ClanMachineEntryNode:registerListener()
    gLobalNoticManager:addObserver(self, "updateProgUI", ClanConfig.EVENT_NAME.UPDATE_MACHINE_ENTRY_PROG) -- 更新关卡内入口的进度
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN) -- 收到 玩家 退出公会
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.RECIEVE_CLAN_CREATE_SUCCESS) -- 创建公会成功
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.SEND_SYNC_CLAN_ACT_DATA) -- 同步公会配套的活动数据
    gLobalNoticManager:addObserver(self, "enterClanSystem", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA) -- 请求接收到公会基础数据
    gLobalNoticManager:addObserver(self, "enterClanSystem", ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD) -- 请求接收到公会基础数据_faild
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.RECIEVE_JOIN_CLAN_SUCCESS) -- 加入公会成功
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.RECIEVE_FAST_JOIN_CLAN_SUCCESS) -- 快速加入公会成功
    gLobalNoticManager:addObserver(self, "changeBetValueEvt", ViewEventType.NOTIFY_CLICK_BET_CHANGE) -- 切换bet值
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
    gLobalNoticManager:addObserver(self, "updateUI", ClanConfig.EVENT_NAME.REFRESH_ENTRY_UI) -- 刷新关卡入口UI
end

-- 监测 有小红点或者活动进度满了
function ClanMachineEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    if self.spRedDot then
        bHadRed = self.spRedDot:isVisible() 
    end
    local bProgMax = false
    if self.m_progBar then
        bProgMax = self.m_progBar:getPercent() >= 100
    end
    return {bHadRed, bProgMax}
end

return ClanMachineEntryNode
