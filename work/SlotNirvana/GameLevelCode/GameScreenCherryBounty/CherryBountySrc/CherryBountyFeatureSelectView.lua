--[[
    玩法选择
]]
local SendDataManager = require "network.SendDataManager"
local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyFeatureSelectView = class("CherryBountyFeatureSelectView", util_require("Levels.BaseLevelDialog"))

function CherryBountyFeatureSelectView:initUI(_data)
    --[[
        _data = {
            machine         = machine
            bCommon         = true
            csbName         = "xxx.csb"
            spineName       = "xxx"
            animNameSuffix  = "_2"
            coins           = 0,
        }
    ]]
    self.m_initData = _data
    self.m_machine  = _data.machine
    self.m_allowClick = false

    self:createCsbNode(_data.csbName)
    self.m_spine = util_spineCreate(_data.spineName, true, true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    if self.m_initData.bCommon then
        local sCoins = util_formatCoinsLN(_data.coins, 3)
        local labCoins = self:findChild("m_lb_coins")
        labCoins:setString(sCoins)
        self:updateLabelSize({label=labCoins, sx=0.64, sy=0.64}, 145)

        self:addClick(self:findChild("Panel_click1"))
        self:addClick(self:findChild("Panel_click2"))
        self:addClick(self:findChild("Panel_click3"))
        self:addClick(self:findChild("Panel_click4"))
    else
        self:addClick(self:findChild("Panel_click1"))
        self:addClick(self:findChild("Panel_click2"))
    end
end

--点击动画回调
function CherryBountyFeatureSelectView:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end
--结束回调
function CherryBountyFeatureSelectView:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

function CherryBountyFeatureSelectView:onEnter()
    CherryBountyFeatureSelectView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
    self:playStartAnim()
end
--时间线-弹出
function CherryBountyFeatureSelectView:playStartAnim()
    local startName = string.format("start%s", self.m_initData.animNameSuffix)
    util_spinePlay(self.m_spine, startName, false)
    util_spineEndCallFunc(self.m_spine,  startName, function()
        local idleName = string.format("idleframe%s", self.m_initData.animNameSuffix)
        util_spinePlay(self.m_spine, idleName, true)
        self.m_allowClick = true
    end)
    if self.m_initData.bCommon then
        util_spinePushBindNode(self.m_spine, "Node_shuzi", self:findChild("shuzi"))
    end
end

--点击回调
function CherryBountyFeatureSelectView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    self.m_allowClick = false

    local name = sender:getName()
    self.m_selectIndex = 1
    if name == "Panel_click2" then
        self.m_selectIndex = 2
    elseif name == "Panel_click3" then
        self.m_selectIndex = 3
    elseif name == "Panel_click4" then
        self.m_selectIndex = 4
    end
    self:sendData(self.m_selectIndex)
end
--数据发送
function CherryBountyFeatureSelectView:sendData(_selectIndex)
    if self.m_isWaiting then
        return
    end
    self.m_isWaiting = true

    local select = self:getSelectTypeByIndex(self.m_initData.bCommon, _selectIndex)
    local messageData = {}
    messageData.msg  = MessageDataType.MSG_BONUS_SELECT
    messageData.data = select
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end
--数据返回
function CherryBountyFeatureSelectView:featureResultCallFun(_params)
    if not self.m_isWaiting then
        return
    end
    if _params[1] == true then
        local spinData = _params[2]
        if spinData.action == "FEATURE" then
            self.m_isWaiting = false
            local result = spinData.result
            self.m_machine.m_runSpinResultData:parseResultData(spinData.result, self.m_machine.m_lineDataPool)
            self.m_machine:operaWinCoinsWithSpinResult(_params)
            self:playClickAnim(result)
        end
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

--时间线-选中
function CherryBountyFeatureSelectView:playClickAnim(_result)
    if self.m_initData.bCommon then
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_SelectView4_click)
    else
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_SelectView2_click)
    end
    local selfData   = _result.selfData or {}
    local selectType = selfData.kind or ""
    local selectIndex = self:getSelectIndexByType(self.m_initData.bCommon, selectType)
    local animName = string.format("actionframe%d", selectIndex)
    animName = string.format("%s%s", animName, self.m_initData.animNameSuffix)
    util_spinePlay(self.m_spine, animName, false)
    self.m_machine:levelPerformWithDelay(self, 45/30, function()
        if self.m_btnClickFunc then
            self.m_btnClickFunc(_result)
            self.m_btnClickFunc = nil
        end
        self.m_machine:levelPerformWithDelay(self, 15/30, function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc(_result)
                self.m_overRuncallfunc = nil
            end
            self:removeFromParent()
        end)
    end)
end

--选择索引->选择类型
function CherryBountyFeatureSelectView:getSelectTypeByIndex(_bCommon, _selectIndex)
    local selectList = self:getSelectTypeList(_bCommon)
    local selectType = selectList[_selectIndex]
    return selectType
end
--选择类型->选择索引
function CherryBountyFeatureSelectView:getSelectIndexByType(_bCommon, _selectType)
    local selectList  = self:getSelectTypeList(_bCommon)
    for i,v in ipairs(selectList) do
        if v == _selectType then
            return i
        end
    end
    return 1
end
--选择类型列表
function CherryBountyFeatureSelectView:getSelectTypeList(_bCommon)
    if _bCommon then
        return { "free3", "free2", "free1", "respin" }
    else
        return { "jackpot", "super_respin" }
    end
end

return CherryBountyFeatureSelectView