--升级界面

local Logonfailure = class("Logonfailure", util_require("base.BaseView"))
function Logonfailure:initUI(isFb,isTest)
    local path = "Logon/Logonfailure.csb"
    if isFb then
        path = "Logon/FBLogonfailure.csb"
    end
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    self:createCsbNode(path,isAutoScale)
    self.m_lb_failed = self:findChild("lab_failed")
    self.m_lb_timeOut = self:findChild("lab_time_out")
    self.m_lb_timeOut_1 = self:findChild("lab_time_out_1")
    if isTest then
        self.m_lb_failed:setVisible(false)
        self.m_lb_timeOut:setVisible(false)
        if self.m_lb_timeOut_1 then
            self.m_lb_timeOut_1:setVisible(true)
        end

    end
    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(root,function()
        end)
    else
        self:runCsbAction("show",false)
    end

end

--失败描述
function Logonfailure:setFailureDescribe(errorData)
    local errorCode = nil
    if errorData ~= nil then
        errorCode = errorData[2]
    end

    if errorCode ~= nil and  string.find(errorCode, "Request Timestamp Has Expired") ~= nil then
        self.m_lb_failed:setVisible(false)
        self.m_lb_timeOut:setVisible(true)
        if self.m_lb_timeOut_1 then
            self.m_lb_timeOut_1:setVisible(false)
        end
    else
        self.m_lb_failed:setVisible(true)
        self.m_lb_timeOut:setVisible(false)
        if self.m_lb_timeOut_1 then
            self.m_lb_timeOut_1:setVisible(false)
        end

    end
end

function Logonfailure:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        --globalNoviceGuideManager:NextShow()
        if globalNoviceGuideManager then
            globalNoviceGuideManager:attemptShowRepetition()
        end
        local root = self:findChild("root")
        if root then
            self:commonHide(root,function()
                self:removeFromParent(true)
            end)
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:removeFromParent()
         end
      end
end


return Logonfailure