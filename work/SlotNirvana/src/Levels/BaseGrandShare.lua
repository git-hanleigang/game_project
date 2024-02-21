--[[
    Grand分享
    使用系统csb,系统管理者,新增的数据解析,关卡底层新增方法 全部判空
]]
local BaseGrandShare = class("BaseGrandShare", util_require("Levels.BaseLevelDialog"))

BaseGrandShare.ShareState = {
    Normal = 0,
    Start  = 1,
}
BaseGrandShare.CheckBoxState = {
    Normal = 0,
    Tick   = 1,
}
--[[
    _initData = {
        machine = mainMachine
    }
]]
function BaseGrandShare:initUI(_initData)
    self.m_machine       = _initData.machine
    self.m_shareState    = self.ShareState.Normal
    self.m_checkBoxState = self.CheckBoxState.Normal
    --暂停恢复回调
    self.m_fnResumeGame = nil
    --系统那边的截图路径
    self.m_screenCapturePath = ""

    local csbPath = "CommonButton/csb/CommonButton_GrandShare.csb"
    if cc.FileUtils:getInstance():isFileExist(csbPath) then
        self:createCsbNode(csbPath)
        self:initCheckBox()
    end
    
    --默认不分享
    self:setVisible(false)
    self:setCheckBoxState(false)
end

function BaseGrandShare:onEnter()
    BaseGrandShare.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self, true)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:runResumeGameCallBack()
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end
function BaseGrandShare:onExit()
    if "" ~= self.m_screenCapturePath then
        local grandShareMgr = G_GetMgr(G_REF.MachineGrandShare)
        util_printLog(string.format("[BaseGrandShare:onExit] 清理分享图片 %s", self.m_screenCapturePath), true)
        grandShareMgr:deleteSaveImgByPath(self.m_screenCapturePath)
        self.m_screenCapturePath = ""
    end

    -- 20级以上，在关卡中Grand的档次Spin结算之后弹出，触发优先级高于SpinWin、SpecailWin和SpecailWinV2，触发的时候不会触发前面几个点。单独弹板，弹板CD为0，点位CD24小时。触发的时候重置SpinWin和SpecailWin的点位CD。另外，没有Grand分享或没有Grand的关卡不弹。
    -- cxc 2024年01月02日12:12:28 
    if self:isVisible() then -- 显示说明支持 grand分享
        G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("GrandWin")
    end
    
    BaseGrandShare.super.onExit(self)
end



function BaseGrandShare:checkAutoShareType(_jpIndex)
    local bool = false
    local jackpotShare = {}
    if self.m_machine.getCurLevelMachineData then
        local machineData  = self.m_machine:getCurLevelMachineData() 
        jackpotShare = machineData:getJackpotShare()
    end
    
    local listIndex    = 1
    while nil ~= jackpotShare[listIndex] do
        local cfgJackpotIndex = jackpotShare[listIndex]
        if cfgJackpotIndex == _jpIndex then
            bool = true
            break
        end
        listIndex = listIndex + 1
    end

    return bool
end
--弹板金币上涨完毕回调
function BaseGrandShare:jumpCoinsFinish(_jpIndex)
    local bAutoShare = self:checkAutoShareType(_jpIndex)
    if bAutoShare then
        self:startAutoSaveCurScreen()
    end
    --刷新复选框状态
    self:setCheckBoxState(bAutoShare)
end

function BaseGrandShare:startAutoSaveCurScreen()
    local grandShareMgr = G_GetMgr(G_REF.MachineGrandShare)
    if not grandShareMgr then
        return
    end

    local bGamePause = self.m_machine:checkGameRunPause()
    if bGamePause then
        util_printLog("[BaseGrandShare:startAutoSaveCurScreen] 注册暂停结束回调", true)
        self:setResumeGameCallBack(function()
            util_printLog("[BaseGrandShare:startAutoSaveCurScreen] 执行暂停结束回调", true)
            self:startAutoSaveCurScreen()
        end)
        return
    else
        self:setResumeGameCallBack(nil)
        util_printLog("[BaseGrandShare:startAutoSaveCurScreen] 开始截屏", true)
        self:setShareState(self.ShareState.Start)
        local machineData = self.m_machine:getCurLevelMachineData() 
        local gameId      =  machineData.p_id
        grandShareMgr:saveCurScreenImgFile(gameId, function(_imgPath)
            util_printLog("[BaseGrandShare:startAutoSaveCurScreen] 截屏完毕", true)
            self.m_screenCapturePath = _imgPath
            self:setShareState(self.ShareState.Normal)
            self:playShareBtnStartAnim()
        end)
    end
end

function BaseGrandShare:setResumeGameCallBack(_fun)
    self.m_fnResumeGame = _fun
end
function BaseGrandShare:runResumeGameCallBack()
    if "function" == type(self.m_fnResumeGame) then
        performWithDelay(self,function()
            -- 规避1帧内抛送两次恢复事件时 该变量被注册接口内部清空 第二次调用报错问题
            if "function" == type(self.m_fnResumeGame) then
                self.m_fnResumeGame()
            end
        end, 0)
    end
end

--是否正在分享
function BaseGrandShare:setShareState(_shareState)
    self.m_shareState = _shareState
end
function BaseGrandShare:checkShareState()
    local bShare = self.m_shareState ~= self.ShareState.Normal
    return bShare
end

function BaseGrandShare:playShareBtnStartAnim()
    self:setVisible(true)
    self:runCsbAction("start", false)
end


--[[
    复选框
]]
function BaseGrandShare:initCheckBox()
    self.m_checkBoxNode = self:findChild("cb_grand") 
    if self.m_checkBoxNode then
        self.m_checkBoxNode:onEvent(function(event)
            if event.name == "selected" then
                self:setCheckBoxState(true)
            elseif event.name == "unselected" then
                self:setCheckBoxState(false)
            end
        end)
    end
end
function BaseGrandShare:setCheckBoxState(_bSelect)
    if self.m_checkBoxNode then
        self.m_checkBoxState = _bSelect and self.CheckBoxState.Tick or self.CheckBoxState.Normal
        self.m_checkBoxNode:setSelected(_bSelect)
    end
end
function BaseGrandShare:checkCheckBoxState()
    local bCheckBoxState = self.m_checkBoxState == self.CheckBoxState.Tick
    return bCheckBoxState
end

--弹板关闭时检测复选框状态
function BaseGrandShare:jackpotViewOver(_fun)
    _fun = _fun or function() end
    local bCheckBoxState = self:checkCheckBoxState()
    if bCheckBoxState then
        --FB手动分享
        self:FBScreenCaptureShare(function()
            self:playShareBtnOverAnim()
            _fun()
        end)
    else
        self:playShareBtnOverAnim()
        _fun()
    end    
end


--弹板关闭准备关闭时
function BaseGrandShare:FBScreenCaptureShare(_fun)
    local grandShareMgr = G_GetMgr(G_REF.MachineGrandShare)
    if not grandShareMgr then
        _fun()
        return
    end

    util_printLog("[BaseGrandShare:clickFunc] FB分享", true)
    self:setShareState(self.ShareState.Start)
    grandShareMgr:shareToFb(self.m_screenCapturePath, function(_succuessCode)
        util_printLog("[BaseGrandShare:clickFunc] FB分享完毕", true)
        self:setShareState(self.ShareState.Normal)
        _fun()
    end)
end

--弹板关闭准备关闭时
function BaseGrandShare:FBScreenCaptureShare(_fun)
    local grandShareMgr = G_GetMgr(G_REF.MachineGrandShare)
    if not grandShareMgr then
        _fun()
        return
    end

    util_printLog("[BaseGrandShare:FBScreenCaptureShare] FB分享", true)
    self:setShareState(self.ShareState.Start)

    --FB分享可能遇到分享回调不被触发的情况加一个前台监听(监听注册接口内有重复判断 这么加就行)
    gLobalNoticManager:addObserver(self, function()
        if not self:checkShareState() then
            return
        end
        gLobalNoticManager:removeObserver(self, ViewEventType.APP_ENTER_FOREGROUND_EVENT)

        util_printLog("[BaseGrandShare:clickFunc] 用户返回前台", true)
        self:setShareState(self.ShareState.Normal)
        _fun()
    end, ViewEventType.APP_ENTER_FOREGROUND_EVENT)

    grandShareMgr:shareToFb(self.m_screenCapturePath, function(_succuessCode)
        if tolua.isnull(self) then
            return
        end
        if not self:checkShareState() then
            return
        end
        gLobalNoticManager:removeObserver(self, ViewEventType.APP_ENTER_FOREGROUND_EVENT)

        util_printLog("[BaseGrandShare:FBScreenCaptureShare] FB分享完毕", true)
        self:setShareState(self.ShareState.Normal)
        _fun()
    end)
end

function BaseGrandShare:playShareBtnOverAnim()
    self:runCsbAction("over", false)
end

return BaseGrandShare