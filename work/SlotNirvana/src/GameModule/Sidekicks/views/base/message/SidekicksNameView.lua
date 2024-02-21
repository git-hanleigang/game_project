--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-22 20:25:49
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-18 15:51:49
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/message/SidekicksNameView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-14 17:10:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-14 20:42:16
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/season/season_1/message/SidekicksNameView.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksNameView = class("SidekicksNameView", BaseView)
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function SidekicksNameView:initDatas(_seasonIdx)
    SidekicksNameView.super.initDatas(self)

    self._seasonIdx = _seasonIdx
end

function SidekicksNameView:initCsbNodes()
    SidekicksNameView.super.initCsbNodes(self)

    self._textFieldName = self:findChild("TextField_name")
    self._eboxName = util_convertTextFiledToEditBox(self._textFieldName, nil, function(_evtName, _target)
        if _evtName == "changed" or _evtName == "return" then
            self:refreshPetName(_evtName == "return")
        end
    end)
    self._eboxName:setLocalZOrder(2) 
    self:findChild("btn_change"):setLocalZOrder(99)
end

function SidekicksNameView:getCsbName()
    return string.format("Sidekicks_%s/csd/message/Sidekicks_Message_name.csb", self._seasonIdx)
end

function SidekicksNameView:updateUI(_petInfo)
    self._petInfo = _petInfo

    local name = self._petInfo:getName()
    self._textFieldName:setPlaceHolder(name)
    self._eboxName:setPlaceHolder(name)
    self._eboxName:setText(name)
end

function SidekicksNameView:refreshPetName(_bSaveName)
    local name = self._eboxName:getText()
    name = SensitiveWordParser:getString(name, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
    name = string.gsub(name, "[^%w]", "")

    self._eboxName:setText(name)
    if _bSaveName then
        self:checkSaveNewName()
    end
    self._textFieldName:setPlaceHolder(name)
end

function SidekicksNameView:checkSaveNewName(sender)
    local newName = self._eboxName:getText()
    local oldName = self._petInfo:getName()
    if newName == oldName then
        return
    end

    G_GetMgr(G_REF.Sidekicks):sendSyncPetName(self._petInfo:getPetId(), newName)
end

return SidekicksNameView