--账号删除恢复
local AccountRecoverLayer = class("AccountRecoverLayer", BaseLayer)

function AccountRecoverLayer:initDatas(_data)
    AccountRecoverLayer.super.initDatas(self)
    self.m_desData = {}
    self.m_code = 0
    -- self.data = _data
    if _data and _data:HasField("description") then
        if _data.description and _data.description ~= "" then
            self.m_desData = cjson.decode(_data.description)
        end
        self.code = _data.code
    end
    
    self:setLandscapeCsbName("Dialog/DeleteAccount_loginTips.csb")
end

function AccountRecoverLayer:initCsbNodes()
    self.btn_no1 = self:findChild("btn_no1")
    self.btn_no = self:findChild("btn_no")
    self.btn_yes = self:findChild("btn_yes")
    self.label_big = self:findChild("lb_text1")
    self.label_bigtime = self:findChild("lb_time1")
    self.label_small = self:findChild("lb_text2")
end

function AccountRecoverLayer:initView()
    -- local data = self.data
    -- local code = data.code
    -- self.code = code
    local timestr = ""

    if self.m_desData["DeleteUserExpire"] then
        self.misTime = tonumber(self.m_desData["DeleteUserExpire"])
        timestr = self:leftDays(self.misTime)
        self.m_timeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    end
    self.time_label = self.label_bigtime
    if self.code == BaseProto_pb.ACCOUNT_DELETING then
        self.btn_no1:setVisible(false)
        self.label_small:setVisible(false)
    elseif self.code == BaseProto_pb.ACCOUNT_DELETED then
        self.btn_no1:setVisible(true)
        self.btn_no:setVisible(false)
        self.btn_yes:setVisible(false)
        self.label_big:setVisible(false)
    end
    self.time_label:setString(timestr)
end

function AccountRecoverLayer:updateLeftTimeUI()
    self.misTime = self.misTime - 1
    if self.misTime > 0 then
        self.time_label:setString(self:leftDays(self.misTime))
    else
        if self.m_timeScheduler then
            self:stopAction(self.m_timeScheduler)
            self.m_timeScheduler = nil
        end
        if self.code == BaseProto_pb.ACCOUNT_DELETING then
            self:exitGame()
        end
    end
end

function AccountRecoverLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_no" or name == "btn_no1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:exitGame()
    elseif name == "btn_yes" then
        local udid = gLobalSendDataManager:getDeviceUuid()
        udid = tostring(self.m_desData["udid"] or udid)

        gLobalSendDataManager:getNetWorkLogon():sendRecoverAccount(udid)
        if self.m_timeScheduler then
            self:stopAction(self.m_timeScheduler)
            self.m_timeScheduler = nil
        end
        self:closeUI()
    end
end

function AccountRecoverLayer:exitGame()
    if device.platform == "ios" then
        os.exit()
    else
        local director = cc.Director:getInstance()
        director:endToLua()
    end
end

function AccountRecoverLayer:leftDays(time)
    local str = ""
    if time > 86400 then
        local day = math.floor(time / 86400)
        str = string.format("%d DAY", day)
    else
        str = util_count_down_str(time)
    end
    return str
end

return AccountRecoverLayer
