
local UserInfoNet = require("GameModule.UserInfo.net.UserInfoNet")
local UserInfoManager = class("UserInfoManager",BaseGameControl)
local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")

function UserInfoManager:ctor()
    UserInfoManager.super.ctor(self)
    self:setRefName(G_REF.UserInfo)
    self.defult_item = 1
    self.m_checkItemId = 1
    self.item_data = {}
end

function UserInfoManager:getData()
    return globalData.userInfoData
end

function UserInfoManager:getConfig()
    if not self.UserConfig then
        self.UserConfig = util_require("GameModule.UserInfo.config.UserInfoConfig")
    end
    return self.UserConfig
end

function UserInfoManager:isDownloadRes(_name)
    if not self:checkRes(_name) then
        return false
    end

    local isDownloaded = self:checkDownloaded(_name)
    if not isDownloaded then
        return false
    end

    return true
end

function UserInfoManager:showMainLayer(_type)
    if not self:isDownloadRes(G_REF.UserInfo) then
        return nil
    end
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("UserInfoMainLayer") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserInfoMainLayer")
        if MainUI ~= nil then
            self.m_checkItemId = 1
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
            if _type ~= nil and _type ~= 1 then
                self:setFrameItem(2)
                gLobalNoticManager:postNotification(self:getConfig().ViewEventType.MAIN_IN,_type)
            end
        end
    end
    return MainUI 
end

function UserInfoManager:showEmailLayer()
    local EmailUI = nil
    if gLobalViewManager:getViewByExtendData("UserInfoBindEmail") == nil then
        EmailUI = util_createFindView("views/UserInfo/view/UserInfoBindEmail")
        if EmailUI ~= nil then
            self:showLayer(EmailUI,ViewZorder.ZORDER_UI)
        end
    end
    return EmailUI 
end

function UserInfoManager:showEditNameLayer()
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("UserInfoChangeName") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserInfoChangeName")
        if MainUI ~= nil then
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
        end
    end
    return MainUI 
end

function UserInfoManager:showInfoMation(_data)
    if not self:isDownloadRes(G_REF.UserInfo) then
        return nil
    end
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("UserInfoMation") == nil then
        -- 比赛机器人段位修改成自己的段位（客户端处理）
        if gLobalViewManager:getViewByExtendData("League_MainLayer") and _data and _data.robot and #_data.robot > 0 then
            local myDivision = G_GetMgr(G_REF.LeagueCtrl):getMyDivision()
            _data.league = myDivision or _data.league
        end
        MainUI = util_createFindView("views/UserInfo/view/UserInfoMation", _data)
        if MainUI ~= nil then
            gLobalViewManager:showUI(MainUI,ViewZorder.ZORDER_POPUI)
        end
    end
    return MainUI 
end
--3个头像框展示页
function UserInfoManager:showFrameDisy()
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("FrameDisyLayer") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserPerson/FrameDisyLayer")
        if MainUI ~= nil then
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
        end
    end
    return MainUI 
end
--成就系统
function UserInfoManager:showAchievements()
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("CashDisyLayer") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserPerson/CashDisyLayer")
        if MainUI ~= nil then
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
        end
    end
    return MainUI 
end

--成就规则
function UserInfoManager:showAchieveRule(params)
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("CashDisyRuleLayer") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserPerson/CashDisyRuleLayer",params)
        if MainUI ~= nil then
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
        end
    end
    return MainUI 
end

-- 生日信息编辑界面
function UserInfoManager:showBirthdayEditLayer()
    local MainUI = nil
    if gLobalViewManager:getViewByExtendData("UserInfoBirthdayEditLayer") == nil then
        MainUI = util_createFindView("views/UserInfo/view/UserInfoBirthdayEditLayer")
        if MainUI ~= nil then
            self:showLayer(MainUI,ViewZorder.ZORDER_UI)
        end
    end
    return MainUI 
end

function UserInfoManager:removeAllItem()
    self.item_data = {}
end

function UserInfoManager:addDefultItem(node,_idx)
    self.item_data[_idx] = node
end

function UserInfoManager:setItemVisible(_idx)
    local node = nil
    for i,v in pairs(self.item_data) do
        v:setVisible(i == _idx)
        if i == _idx then
            node = v
        end
    end
    return node
end

--高倍场等级
function UserInfoManager:getHighLevel()
    local deluexeCurrPoint = globalData.deluexeClubData.p_currPoint
    local deluextTotalPoint = globalData.constantData.CLUB_OPEN_POINTS
    local floatDelPercent = deluexeCurrPoint / deluextTotalPoint
    floatDelPercent = floatDelPercent > 1 and 1 or floatDelPercent
    return deluexeCurrPoint .. "/" .. deluextTotalPoint
end

--VIP等级
function UserInfoManager:getVipLevel()
    local vipLevel = globalData.userRunData.vipLevel
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost and vipBoost:isOpenBoost() then
        local extraLevel = vipBoost:getBoostVipLevelIcon()
        if extraLevel > 0 then
            vipLevel = vipLevel + extraLevel
        end
    end

    return vipLevel
end

function UserInfoManager:saveNickName(_nickName,_mail,_headId,_sendOption,_isEmail,_frameId,tp,typeRmove)
    local extraInfo = {}
    if _headId and string.len(tostring(_headId)) > 0 then
        extraInfo["headName"] = _headId 
    end
    if _frameId and string.len(tostring(_frameId)) > 0 then
        extraInfo["avatarFrameId"] = _frameId 
    end
    if typeRmove ~= nil then
        extraInfo["avatarFrameId"] = ""
    end
    local successCallFun = function(responseTable)
        if self:isFristBindEmail() and string.len(_nickName) == 0 and string.len(_mail) ~= 0 then
            UserInfoNet:sendActionEmailRewardReq()
        end
        gLobalNoticManager:postNotification(self:getConfig().ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC)
    end

    local failedCallFunFail = function(errorCode, errorData)
        gLobalNoticManager:postNotification(self:getConfig().ViewEventType.NOTIFY_USERINFO_MODIFY_FAIL)
    end
    UserInfoNet:sendNameHeadReq(_nickName,_mail,extraInfo,_sendOption,_isEmail,successCallFun,failedCallFunFail)
end

-- 获取玩家 背包信息
function UserInfoManager:sendUserBagInfoReq()
    UserInfoNet:sendUserBagInfoReq()
end

function UserInfoManager:setHistory(_data)
    self.m_history = {}
    if _data and _data.legendaryWinTimesTotal then
        self.m_history.m_legendaryWinTimesTotal = _data.legendaryWinTimesTotal
        self.m_history.m_spinTimesTotal = _data.spinTimesTotal
        self.m_history.m_maximumWinMultiple = _data.maximumWinMultiple
        self.m_history.m_maximumWin = _data.maximumWin
        self.m_history.m_bigwin = _data.bigWinTimesTotal
        self.m_history.m_megawin = _data.megaWinTimesTotal
        self.m_history.m_epicwin = _data.epicWinTimesTotal
        self.m_history.m_jackpot = _data.jackpotTimes
    end
end

function UserInfoManager:getHistory()
    return self.m_history or {}
end

--点击玩家获取信息
function UserInfoManager:sendInfoMationReq(_uuid,_robot,_nickName,_frame,_type)
     local successCallFun = function(responseTable)
        if responseTable then
            if not responseTable.udid then
                responseTable.udid = _uuid
            end
            if _type and _type == 1 then
                self:setHistory(responseTable)
            else
                self:showInfoMation(responseTable)
            end
        end
     end 
     local failedCallFunFail = function(errorCode)
        self:setHistory({})
     end 
     UserInfoNet:sendInfomationReq(_uuid,_robot,_nickName,_frame,successCallFun,failedCallFunFail,_type)
end

--存储玩家喜欢的头像框
function UserInfoManager:sendFrameLikenReq(_like_list)
     local successCallFun = function(responseTable)
        if responseTable then
            G_GetMgr(G_REF.AvatarFrame):updateLikeFrame(responseTable.favoriteFrame)
            G_GetMgr(G_REF.AvatarFrame):updateLikeStatus()
            gLobalNoticManager:postNotification(self:getConfig().ViewEventType.FRAME_LIKE_SELECT)
        end
     end 
     local failedCallFunFail = function(errorCode)

     end 
     UserInfoNet:sendFrameLikeReq(_like_list,successCallFun,failedCallFunFail)
end

-- 当前选中的背包道具id
function UserInfoManager:setBagCheckItemId(_id)
    self.m_checkItemId = _id
end

function UserInfoManager:getBagCheckItemId()
    if self.m_checkItemId == 1 and self:getData():getChooseItem() ~= nil then
        self.m_checkItemId = self:getData():getChooseItem().id
    end
    return self.m_checkItemId
end

function UserInfoManager:isFristBindEmail()
    return self.m_isFristBindEmail
end

function UserInfoManager:setIsFristBindEmail( _isBindEmail  )
     self.m_isFristBindEmail = _isBindEmail
end

function UserInfoManager:getAvrDes(slot_id,level,_frameId)
    local slot_data = G_GetMgr(G_REF.AvatarFrame):getData():getSlotTaskBySlotId(slot_id)
    if not slot_data then
        return ""
    end
    local taskData = slot_data:getTaskDataByFrameId(_frameId)
    if not taskData then
        return ""
    end
    -- -- 0未激活， 1正在进行， 2已完成
    local status = taskData:getStatus()
    local str = ""
    local desc_level = taskData:getFrameLevelDesc()
    local slot_name = taskData:getSlotGameName()
    if status == 2 then
        local time = taskData:getCompleteTime()
        local t = os.date("*t", time)
        local time_str = string.format("%s %02d, %d", FormatMonth[t.month], t.day, t.year)
        str = "Unlocked in the "..desc_level.." challenge in "..slot_name.." on "..time_str
    else
        str = "Complete the "..desc_level.." challenge in "..slot_name
    end
    return str
end

function UserInfoManager:getAvrPropTimeEndDes(_propFrameId)
    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    if not data then
        return
    end
    local frameCollectData = data:getFrameCollectDataById(_propFrameId)
    if not frameCollectData or not frameCollectData:checkIsTimeLimitType() then
        return
    end

    if not frameCollectData:checkIsEnbaled() then
        return
    end

    local expTime = frameCollectData:getExpireTimeSec()
    return util_daysdemaining(expTime, true) .. " LEFT"
end

function UserInfoManager:getStatus(id)
    local data_list = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameIdList()
    local status = 0
    for i,v in ipairs(data_list) do
        if id == tonumber(data_list[i]) then
            status = 1
        end
    end
    return status
end

function UserInfoManager:getIsNew(id)
    local status = 0
    local str = gLobalDataManager:getStringByField("avrList")
    if str ~= nil and str ~= "" then
        local id_list = cjson.decode(str)
        for i,v in ipairs(id_list) do
            if id == tonumber(v) then
                status = 1
            end
        end
    end
    return status
end

function UserInfoManager:setIsNew(id)
    if id then
        local str = gLobalDataManager:getStringByField("avrList")
        local id_list = {}
        if str ~= nil and str ~= "" then
            id_list = cjson.decode(str)
        end
        table.insert(id_list,id)
        gLobalDataManager:setStringByField("avrList",cjson.encode(id_list)) 
        return
    end
    local data_list = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameIdList()
    if data_list ~= nil and #data_list > 0 then
        local id_list = {}
        for i,v in ipairs(data_list) do
            table.insert(id_list,v)
        end
        gLobalDataManager:setStringByField("avrList",cjson.encode(id_list))
    end
end

function UserInfoManager:getChooseAvr()
    if not self.chooseAvr then
        if globalData.userRunData.avatarFrameId ~= nil and globalData.userRunData.avatarFrameId ~= "" then
            self.chooseAvr = tonumber(globalData.userRunData.avatarFrameId)
        else
            local avterList = self:getCfAllList()
            if avterList and #avterList > 0 then
                self.chooseAvr = avterList[1].id
            end
        end
       
    end
    return self.chooseAvr or 0
end

function UserInfoManager:setChooseAvr(_id)
    self.chooseAvr = _id
end

function UserInfoManager:getAvrDataById(_id)
    local list_data = self:getCfAllList()
    local data = nil
    for i,v in ipairs(list_data) do
        if _id == v.id then
            data = v
        end
    end
    return data
end

function UserInfoManager:getCfItemList()
    local total_list = {}
    local data = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData() or {}
    local _frameCfg_item = data.m_frameCfg_item
    if _frameCfg_item and #(_frameCfg_item.m_totalFrameIdList or {}) > 0 then
        local item_list = _frameCfg_item.m_cfgFrameIdInfoList
        local total_id = _frameCfg_item.m_totalFrameIdList
        for i, v in ipairs(total_id) do
            local itme = item_list[v]
            itme.id = v
            table.insert(total_list, itme)
        end
    end
    if total_list and #total_list then
        total_list = self:setHoldList(total_list)
    end
    return total_list or {}
end

function UserInfoManager:getCfSoltList()
    local data = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData()
    local item_list = data.m_frameCfg_slot.m_cfgFrameIdInfoList
    if item_list and #item_list > 0 then
        item_list = self:setHoldList(item_list)
    end
    return item_list or {}
end

function UserInfoManager:getCfAllList()
    local data = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData()
    local item_list = self:getCfItemList()
    if #item_list > 0 then
        local total_list = {}
        for i,v in ipairs(item_list) do
             table.insert(total_list,v)
        end
        for i,v in ipairs(self:getCfSoltList()) do
             table.insert(total_list,v)
        end
        return total_list
    else
        return self:getCfSoltList()
    end
end

function UserInfoManager:setHoldList(_item)
    local item_list = clone(_item)
    local data_list = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameIdList()
    if data_list and #data_list > 0 then
        local userlist = {}
        local shengyu = {}
        for i=1,#item_list do
            local t = 0
            for k=1,#data_list do
                if item_list[i] and item_list[i].id == tonumber(data_list[k]) then
                    t = 1
                    table.insert(userlist,item_list[i])
                end
            end
            if t == 0 then
                table.insert(shengyu,item_list[i])
            end
        end
        for i,v in ipairs(shengyu) do
            table.insert(userlist,v)
        end
        return userlist
    else
        return item_list
    end
end
--活动头像框
function UserInfoManager:getCfHoldList()
    local data_list = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameTimeList()
    local item_list = self:getCfItemList()
    local userlist = {}
    if data_list and #data_list > 0 then
        for i=1,#item_list do
            for k=1,#data_list do
                local frameTimeData = data_list[k]
                if frameTimeData and item_list[i] and item_list[i].id == tonumber(frameTimeData:getFrameId()) then
                    item_list[i].time = frameTimeData:getExpireTimeSec()
                    table.insert(userlist,item_list[i])
                end
            end
        end
    end
    table.sort( userlist, function(a,b)
        return a.time < b.time
    end)
    return userlist
end
--关卡头像框
function UserInfoManager:getCfHoldSoltList()
    local data_list = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameTimeList()
    local item_list = self:getCfSoltList()
    local userlist = {{},{},{},{},{}}
    if data_list and #data_list > 0 then
        for i=1,#item_list do
            for k=1,#data_list do
                local frameTimeData = data_list[k]
                if frameTimeData and item_list[i] and item_list[i].id == tonumber(frameTimeData:getFrameId()) then
                    item_list[i].time = tonumber(frameTimeData:getExpireTimeSec())
                    table.insert(userlist[item_list[i].frame_level],item_list[i])
                end
            end
        end
    end
    local cf_list = {}
    for i=1,5 do
        local _item = userlist[6-i]
        if _item and #_item > 0 then
            table.sort( _item, function(a,b)
                return a.time < b.time
            end)
            for k,v in ipairs(_item) do
                table.insert(cf_list,v)
            end
        end
    end
    return cf_list
end

function UserInfoManager:getCurrentFrame()
    local current_list = {}
    local item_list = self:getCfHoldList()
    if item_list and #item_list > 0 then
        for i=1,3 do
            if item_list[i] then
                table.insert(current_list,item_list[i])
            end
        end
    end
    local slot_list = self:getCfHoldSoltList() 
    if #current_list < 3 and #slot_list > 0 then
        local num = 3 - #current_list
        for i=1,num do
            if slot_list[i] then
                table.insert(current_list,slot_list[i])
            end
        end
    end
    return current_list
end

--活动头像框分组
function UserInfoManager:getGameHoldFrameItem()
    local num = 0
    local data = self:getCfHoldList()
    if data and #data > 0 then
        num = math.ceil(#data/4)
    end
    return num
end
--关卡头像框分组
function UserInfoManager:getGameFrameItem()
    local num = 0
    local data = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData()
    if data.m_frameCfg_item and data.m_frameCfg_item.m_totalFrameIdList and #data.m_frameCfg_item.m_totalFrameIdList > 0 then
        num = math.ceil(#data.m_frameCfg_item.m_totalFrameIdList/4)
    end
    return num
end

function UserInfoManager:getHeadIndex()
    if not self._headNameId then
        self._headNameId = tonumber(globalData.userRunData.HeadName or 1)
    end
    return self._headNameId
end

function UserInfoManager:setHeadIndex(_id)
    self._headNameId = _id
end

function UserInfoManager:setFrameItem(_id)
    self.frame_item = _id
end

function UserInfoManager:getFrameItem()
    return self.frame_item or 1
end

function UserInfoManager:setNewStatus(_status)
    self.isnewStatus = _status
end

function UserInfoManager:getNewStatus()
    return self.isnewStatus or false
end

function UserInfoManager:getDisyItem()
    if not self.disyItem then
        self.disyItem = {0,0,0}
    end
    return self.disyItem
end
function UserInfoManager:setDisyItem(_id)
    local num,index = 0,0
    if self.disyItem then
        for i,v in ipairs(self.disyItem) do
            if num == 0 and v == 0 then
                num = i
            end
            if v == _id then
                index = i
                self.disyItem[i] = 0
            end
        end
        if index == 0 and num ~= 0 then
            self.disyItem[num] = _id
        end
    else
        self.disyItem = {_id,0,0}
        num = 1
    end
    return num,index
end
function UserInfoManager:clearDisy(_data)
    if _data and #_data > 0 then
        self.disyItem = {0,0,0}
        for i,v in ipairs(_data) do
            self.disyItem[i] = tonumber(v)
        end
    else
        self.disyItem = nil
    end
    
end

--关卡展示顺序
function UserInfoManager:getCashData()
    local id_data = self:getData():getCashData()

    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    local cash_data = {}
    local lock_data = {{},{},{},{},{},{}}
    local unlock_data = {}
    for i,v in ipairs(id_data) do
        local taskData = data:getSlotTaskBySlotId(v)
        local num = taskData:getCompleteNum()
        local item = {}
        item.id = v
        item.num = num
        local slot_data = globalData.slotRunData:getLevelInfoById(v)
        local recm = self:getRecmd(slot_data.p_name)
        if globalData.userRunData.levelNum < slot_data.p_openLevel and not recm and num == 0 then
            item.leveln = slot_data.p_openLevel 
            table.insert(unlock_data,item)
        else
            item.leveln = slot_data.p_openLevel
            table.insert(lock_data[num+1],item)
        end
    end
    local enddata = {}
    for i=1,6 do
        if #lock_data[i] > 1 then
            table.sort( lock_data[i], function(a,b)
                return a.leveln < b.leveln
            end)
        end
    end
    for i=1,6 do
        if #lock_data[7-i] > 0 then
            for j,v in ipairs(lock_data[7-i]) do
                table.insert(enddata,v)
            end
        end
    end
    table.sort( unlock_data,function(a,b)
        return a.leveln < b.leveln
    end)
    local index = #enddata
    for i,v in pairs(unlock_data) do
        enddata[index+i] = v
    end
    return enddata
end

function UserInfoManager:setRecomdGames()
    local recmd = LevelRecmdData:getInstance()
    recmd:freshUnlockLevels()
    local index,_data = recmd:getRecmdInfoByGroup("Frame")
    self.recmdGroup = _data
end

function UserInfoManager:getRecmd(_slotname)
    local ecm = false
    if self.recmdGroup and self.recmdGroup.m_levelNames then
        for i,v in ipairs(self.recmdGroup.m_levelNames) do
            if v == _slotname then
                ecm = true
                break
            end
        end
    end
    return ecm
end

function UserInfoManager:reset()
    self._headNameId = nil
    self._headNameId = nil
    self.chooseAvr = nil
    self.frame_item = nil
    self.m_checkItemId = nil
    self.isnewStatus = false
    self:removeAllItem()
end

--设置进入过主界面
function UserInfoManager:setGoInUserInfoMainLayer(_bGoin)
    self.m_bIsGoInUserInfo = _bGoin
end
--获取玩家是否进入过
function UserInfoManager:isGoInUserInfoMainLayer()
    return self.m_bIsGoInUserInfo
end
-- fb 点击事件
function UserInfoManager:fbBtnTouchEvent()
    if gLobalSendDataManager:getIsFbLogin() == false then

        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_TopIcon)

        else
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos=LOG_ENUM_TYPE.BindFB_TopIcon
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
	    end
    else
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    end
end

return UserInfoManager
