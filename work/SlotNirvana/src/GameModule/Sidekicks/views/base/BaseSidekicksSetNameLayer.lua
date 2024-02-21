--[[
    
--]]

local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local BaseSidekicksSetNameLayer = class("BaseSidekicksSetNameLayer", BaseLayer)

function BaseSidekicksSetNameLayer:initDatas(_seasonIdx, _petInfo)
    self.m_petInfo = _petInfo
    self._seasonIdx = _seasonIdx
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName(string.format("Sidekicks_%s/csd/main/Sidekicks_NamePet.csb", _seasonIdx))
    self:setExtendData("BaseSidekicksSetNameLayer")
end

function BaseSidekicksSetNameLayer:initCsbNodes()
    self.m_lb_name = self:findChild("lb_name1")
end

function BaseSidekicksSetNameLayer:initView()    
    self.m_eboxName = util_convertTextFiledToEditBox(self.m_lb_name, nil, function(_evtName, _target)
        if _evtName == "began" then
            self.m_eboxName.bFirstResponder = true
        elseif _evtName == "changed" then
            self:refreshPetName()
        elseif _evtName == "return" then
            self:refreshPetName()

            performWithDelay(self.m_eboxName, function()
                self.m_eboxName.bFirstResponder = false
            end, 0)
        elseif string.find(_evtName, "keyboradMove") then
            if not GD.KeyBoardChangeFrameInfo or not self.m_eboxName.bFirstResponder then
                return
            end

            local duration = KeyBoardChangeFrameInfo["duration"]
            local beginRect = KeyBoardChangeFrameInfo["begin"]
            local endRect = KeyBoardChangeFrameInfo["end"]
            local keyboardCocosPosY = display.height - KeyBoardChangeFrameInfo["end"].y --(AnchorPoint(0,1))
            if math.abs(display.width - endRect.width) > 10 then
                -- 正常 to 分屏   0  （0 0 0 0） -》 （0 641 1024 271）
                util_keyboardChangeMove(duration, -keyboardCocosPosY/2, self)
            elseif math.abs(keyboardCocosPosY - KeyBoardChangeFrameInfo["end"].height) > 10 then
                -- 键盘高度 大于它的实际高度， 底部会空显示黑屏
                util_keyboardChangeMove(duration, -keyboardCocosPosY/2, self)
            else
                util_keyboardChangeMove(duration, keyboardCocosPosY/2, self)
            end
        end
    end)

    local name = self.m_petInfo:getName()
    self.m_eboxName:setMaxLength(11)
    self.m_eboxName:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self.m_eboxName:setPlaceHolder("")
    -- self.m_eboxName:setText(name)

    self:setButtonLabelContent("btn_ok", "OK")
    self:setButtonLabelDisEnabled("btn_ok", false)
end

function BaseSidekicksSetNameLayer:refreshPetName()
    local name = self.m_eboxName:getText()
    name = SensitiveWordParser:getString(name, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
    name = string.gsub(name, "[^%w]", "")
    self.m_eboxName:setText(name)
    self:setButtonLabelDisEnabled("btn_ok", name ~= "")
end

function BaseSidekicksSetNameLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_ok" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local name = self.m_eboxName:getText()
        local oldName = self.m_petInfo:getName()
        if name ~= "" and name ~= oldName then
            local petId = self.m_petInfo:getPetId()
            G_GetMgr(G_REF.Sidekicks):sendSyncPetName(petId, name)
            gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_PET_SET_NAME, {name = name, petId = petId})
        end
        
        self:closeUI(nil, true)
    end
end

function BaseSidekicksSetNameLayer:getPageCount()
    return 1
end

function BaseSidekicksSetNameLayer:closeUI(_cb, _bOk)
    local cb = function()
        if _cb then
            _cb()
        end

        -- 改名后触发 下一步引导
        local mainLayer = gLobalViewManager:getViewByName(string.format("SidekicksMainLayer_%s", self._seasonIdx))
        if mainLayer then
            mainLayer:dealGuideLogic()
            local name = self.m_petInfo:getName()
            if _bOk then
                name = self.m_eboxName:getText()
            end
            gLobalNoticManager:postNotification(SidekicksConfig.EVENT_NAME.NOTIFY_SIDEKICKS_PET_SET_NAME_GUIDE, name)
        end
    end
    BaseSidekicksSetNameLayer.super.closeUI(self, cb)
end

return BaseSidekicksSetNameLayer