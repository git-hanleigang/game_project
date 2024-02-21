--[[
    @desc: 
    author:JohnnyFred
    time:2021-06-07 14:42:29
]]
local LoadingFixDialog = class("LoadingFixDialog", BaseLayer)

function LoadingFixDialog:initUI(errorMsg)
    self.errorMsg = errorMsg
    self:setLandscapeCsbName("res/Dialog/LoadingFailed.csb")
    LoadingFixDialog.super.initUI(self)
end

function LoadingFixDialog:initCsbNodes()
    self:setButtonLabelContent("btn_contactus", "CONTACT US")
    self:setButtonLabelContent("btn_fixnow", "FIX NOW")
end

function LoadingFixDialog:onEnter()
    LoadingFixDialog.super.onEnter(self)

    gLobalSendDataManager:getLogGameLoad():sendLoginUILog("LoginFix", "Open")
end

function LoadingFixDialog:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_fixnow" then
        if util_fixHotUpdate then
            util_fixHotUpdate(false)
        end
    elseif name == "btn_contactus" then
        if DEBUG == 2 then
            self:showErrorMsg()
        else
            self:contactUS()
        end
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function LoadingFixDialog:showErrorMsg()
    local curScene = cc.Director:getInstance():getRunningScene()
    local view = util_createView("views.logon.Logonfailure", false, true)
    curScene:addChild(view, 99999, 99999)
    view:findChild("Logon_warning_2"):setVisible(false)
    view:findChild("lab_describ_1_1"):setString("errorMessage " .. tostring(self.errorMsg) .. "\n" .. tostring(debug.traceback()))
    if globalData.userRunData ~= nil then
        view:findChild("lab_describ_2_1"):setString("globalData.userRunData.userUdid " .. globalData.userRunData.userUdid)
    end
end

function LoadingFixDialog:contactUS()
    globalData.newMessageNums = nil
    globalData.skipForeGround = true
    globalPlatformManager:openAIHelpRobot("GameLoad")
end

return LoadingFixDialog