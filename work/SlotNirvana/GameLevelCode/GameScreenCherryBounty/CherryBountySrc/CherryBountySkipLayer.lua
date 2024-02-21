--[[
    跳过
]]
local CherryBountySkipLayer = class("CherryBountySkipLayer", util_require("base.BaseView"))

function CherryBountySkipLayer:initUI(_machine)
    self.m_machine = _machine
    self.m_skipSoundList = {}

    self:createCsbNode("CherryBounty_skip.csb")
    self.m_skipLay = self:findChild("Panel_skip")
    self:addClick(self.m_skipLay)
end


CherryBountySkipLayer.SkipLayerSize = {
    Common  = cc.size(876, 400),
    Special = cc.size(1228, 400),
}
--图层-重置宽高
function CherryBountySkipLayer:setSkipLayContentSize(_bCommon)
    local size = self.SkipLayerSize.Common
    if not _bCommon then
        size = self.SkipLayerSize.Special
    end
    local layer = self:findChild("Panel_skip")
    layer:setContentSize(size.width, size.height)
end
--按钮-打开
function CherryBountySkipLayer:initCherryBountySkipLayerBtn()
    self:removeCherryBountySkipLayerBtn()
    self:createCherryBountySkipLayerBtn()
end
--按钮-创建
function CherryBountySkipLayer:createCherryBountySkipLayerBtn()
    local bottomUi = self.m_machine.m_bottomUI
    local spinBtn  = bottomUi.m_spinBtn
    if not self.m_skipBtn and spinBtn then
        local parent = spinBtn:getParent()
        local order  = spinBtn:getLocalZOrder() + 1
        self.m_skipBtn = util_createView("CherryBountySrc.CherryBountyBottomSkipBtn")
        parent:addChild(self.m_skipBtn, order)
        self.m_skipBtn:setGuideScale(spinBtn.m_guideScale)
        self.m_skipBtn:setCherryBountyMachine(self.m_machine)
    end
end
--按钮-关闭
function CherryBountySkipLayer:removeCherryBountySkipLayerBtn()
    if self.m_skipBtn then
        self.m_skipBtn:removeFromParent()
        self.m_skipBtn = nil
    end
end

--流程做延时 可被打断
function CherryBountySkipLayer:skipLayerPerformWithDelay(_time, _fun)
    performWithDelay(self, function()
        if not self:isVisible() then
            return
        end
        _fun()
    end, _time)
end

--播音效 可被打断
function CherryBountySkipLayer:resetSkipSoundList()
    self.m_skipSoundList = {}
end
function CherryBountySkipLayer:skipLayerPlaySound(_soundName, _time)
    local soundId = gLobalSoundManager:playSound(_soundName)
    local soundData = {_soundName, soundId}
    table.insert(self.m_skipSoundList, soundData)
    performWithDelay(self, function()
        for i,_soundData in ipairs(self.m_skipSoundList) do
            if _soundData[1] == soundData[1] and _soundData[2] == soundData[2] then
                table.remove(self.m_skipSoundList, i)
                break
            end
        end
    end, _time)
end
function CherryBountySkipLayer:skipLayerStopSound()
    local list = self.m_skipSoundList
    self.m_skipSoundList = {}
    for i,_soundData in ipairs(list) do
        gLobalSoundManager:stopAudio(_soundData[2])
    end
end



--可跳过流程-开始执行
function CherryBountySkipLayer:showSkipLayer(_skipIndex, _skipData, _skipCallBack)
    --[[
        _skipData = {
            targetList    = {},     --(可选变量)执行收集的列表
            sourceList    = {},     --(可选变量)全部被收集的列表
            targetSymbol  = symbol, --(可选变量)当前执行收集的图标
            newSourceList = {},     --(可选变量)当前执行收集bonus可以收集的列表

            reSpinOverList = {}, --(可选变量)被收集的列表      
        }
    ]]
    self:stopAllActions()
    self:resetSkipSoundList()
    self:saveSkipData(_skipIndex, _skipData, _skipCallBack)
    self:setVisible(true)
    self:initCherryBountySkipLayerBtn()
end
--可跳过流程-保存执行进度
function CherryBountySkipLayer:saveSkipData(_skipIndex, _skipData, _skipCallBack)
    if _skipIndex then
        self.m_skipIndex = _skipIndex
    end
    if _skipData then
        self.m_skipData = _skipData
    end
    if _skipCallBack then
        self.m_skipCallBack = _skipCallBack
    end
end
--可跳过流程-点击跳过
function CherryBountySkipLayer:clickFunc(sender)
    self:clickSkipLayer()
end
function CherryBountySkipLayer:clickSkipLayer()
    local skipIndex  = self.m_skipIndex or 0
    local skipData   = self.m_skipData or {}
    local fnCallBack = self.m_skipCallBack
    --^^^测试代码
    local sMsg = string.format("[CodeGameScreenCherryBountyMachine:clickSkipLayer] %d %s", skipIndex, fnCallBack and "fun" or "nil") 
    print(sMsg)
    release_print(sMsg)
    --^^^测试代码 end
    self:hideSkipLayer()
    self:skipLayerStopSound()
    if "function" == type(fnCallBack) then
        fnCallBack(skipIndex, skipData)
    end
end
--可跳过流程-关闭跳过
function CherryBountySkipLayer:hideSkipLayer()
    self:stopAllActions()
    self.m_skipIndex    = 0
    self.m_skipData     = nil
    self.m_skipCallBack = nil
    self:setVisible(false)
    self:removeCherryBountySkipLayerBtn()
end


return CherryBountySkipLayer