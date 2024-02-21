local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local ZeusVsHadesChooseTeamView = class("ZeusVsHadesChooseTeamView",BaseGame)

function ZeusVsHadesChooseTeamView:initUI(machine,func)
    gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_showChooseView.mp3")
    self:createCsbNode("ZeusVsHades/ChooseYourTeam.csb")
    self.m_machine = machine
    self.m_endFunc = func

    local zeus = util_spineCreate("ZeusVsHades_Zeusidle",true,true)
    self:findChild("Node_Zeus"):addChild(zeus)
    util_spinePlay(zeus,"actionframe5",true)

    local hades = util_spineCreate("ZeusVsHAdes_duijue_HADES",true,true)
    self:findChild("Node_Hades"):addChild(hades)
    util_spinePlay(hades,"actionframe5",true)

    self:addClick(self:findChild("click0"))
    self:addClick(self:findChild("click1"))

    self:setIsCanTouch(false)
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
        self:setIsCanTouch(true)
    end)

    self.m_chooseActionIsEnd = false
    self.m_chooseMessageIsGet = false
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeStatus",{false})
end
--设置是否可以点击触摸
function ZeusVsHadesChooseTeamView:setIsCanTouch(isCanTouch)
    self:findChild("click0"):setTouchEnabled(isCanTouch)
    self:findChild("click1"):setTouchEnabled(isCanTouch)
end
function ZeusVsHadesChooseTeamView:onEnter()
    ZeusVsHadesChooseTeamView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:closeView()
    end,"ZeusVsHadesChooseTeamView_closeView")
end
--接收返回消息
function ZeusVsHadesChooseTeamView:featureResultCallFun(param)
    if param[1] == true then
        --开始刷新房间数据
        gLobalNoticManager:postNotification("CodeGameScreenZeusVsHadesMachine_setCollectCoinNum")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
        gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeUpdateState",{2})
        self.m_chooseMessageIsGet = true
        self:closeView()
    else
        -- 处理消息请求错误情况
        self:setIsCanTouch(true)
    end
end
function ZeusVsHadesChooseTeamView:onExit()
    ZeusVsHadesChooseTeamView.super.onExit(self)
end
--点击回调
function ZeusVsHadesChooseTeamView:clickFunc(sender)
    local name = sender:getName()
    local index = tonumber(string.match(name,"%d+"))
    if index == 0 then
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_chooseZeus.mp3")
    else
        gLobalSoundManager:playSound("ZeusVsHadesSounds/music_ZeusVsHades_chooseHades.mp3")
    end
    self.m_chooseIndex = index
    self:setIsCanTouch(false)
    self:sendData(index)
    self.m_chooseActionIsEnd = false
    self.m_chooseMessageIsGet = false
    gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_resetLogoutTime")
    self:runCsbAction("actionframe"..index,false,function ()
        self.m_chooseActionIsEnd = true
        self:closeView()
    end)
end
--数据发送
function ZeusVsHadesChooseTeamView:sendData(choose)
    self.m_action = self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_TEAM_MISSION_STORE, 
        choose = choose
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--关闭界面
function ZeusVsHadesChooseTeamView:closeView()
    if self.m_chooseActionIsEnd == true and self.m_chooseMessageIsGet == true then
        self:runCsbAction("over"..self.m_chooseIndex,false,function ()
            gLobalNoticManager:postNotification("ZeusVsHadesPlayerLisitView_changeStatus",{true})
            if self.m_endFunc then
                self.m_endFunc()
            end
            self:removeFromParent()
        end)
    end
end

return ZeusVsHadesChooseTeamView