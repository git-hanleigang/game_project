---
--xcyy
--2018年5月23日
--DazzlingDiscoSpotView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoSpotView = class("DazzlingDiscoSpotView",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_UP        =       1001        --向上按钮
local BTN_TAG_DOWN      =       1002        --向下按钮
local BTN_TAG_SHOW_All_PlAYER  =  1003      --显示所有玩家

local MAX_SPOT_COUNT    =       60  --最大点位数量

function DazzlingDiscoSpotView:initUI(params)
    self.m_machine = params.machine
    self.m_roomData = self.m_machine.m_roomData
    self.m_isTouchEnabled = true
    self:createCsbNode("DazzlingDisco_base_spottouxiang.csb")

    self.m_spotItems = {}
    for index = 1,MAX_SPOT_COUNT do
        local item = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotHeadItem",{index = index,parent = self})
        self:findChild("Node_"..index):addChild(item)
        self.m_spotItems[index] = item
        item:runCsbAction("idle")
    end

    self.m_spot_title = util_createAnimation("DazzlingDisco_spot_ui.csb")
    self:findChild("Node_spot_ui"):addChild(self.m_spot_title)
    self.m_btn_up = self.m_spot_title:findChild("Button_1")
    self.m_btn_down = self.m_spot_title:findChild("Button_2")
    self.m_btn_up:setTag(BTN_TAG_UP)
    self.m_btn_down:setTag(BTN_TAG_DOWN)

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:findChild("Node_mask"):addChild(self.m_mask)
    local panel = self.m_mask:findChild("Panel_1")
    panel:setTag(BTN_TAG_DOWN)
    self.m_mask:setVisible(false)

    self:addClick(self.m_btn_up)
    self:addClick(self.m_btn_down)
    self:addClick(panel)

    --显示所有玩家按钮
    self.m_btn_show_players = self.m_spot_title:findChild("panel_show_player")
    self.m_btn_show_players:setTag(BTN_TAG_SHOW_All_PlAYER)
    self:addClick(self.m_btn_show_players)

    self.m_btn_up:setVisible(true)
    self.m_btn_down:setVisible(false)

    self.m_spot_title:findChild("sp_light_up"):setVisible(true)
    self.m_spot_title:findChild("sp_light_down"):setVisible(false)
end

--[[
    显示界面
]]
function DazzlingDiscoSpotView:showView(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_spot_view)
    self:runCsbAction("start")
    self.m_isWaitting = true
    self.m_isShow = true
    self.m_btn_up:setVisible(false)
    self.m_btn_down:setVisible(true)

    self.m_spot_title:findChild("sp_light_up"):setVisible(false)
    self.m_spot_title:findChild("sp_light_down"):setVisible(true)

    self.m_mask:setVisible(true)
    self.m_mask:runCsbAction("animation0")

    self:stopAllActions()

    performWithDelay(self,function(  )
        self.m_isWaitting = false
        if type(func) == "function" then
            func()
        end
    end,30 / 60)
end

--[[
    刷新当前获得的点位
]]
function DazzlingDiscoSpotView:showCurSpotAni(collectData,func)
    if not collectData then
        if type(func) == "function" then
            func()
        end
        return
    end
    local posIndex = collectData.position + 1
    local item = self.m_spotItems[posIndex]
    item:updateHead(collectData)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_spot_trigger_player)
    item:runHitAni(function (  )
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    隐藏界面
]]
function DazzlingDiscoSpotView:hideView(func)
    self.m_isWaitting = true
    self.m_isShow = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_hide_spot_view)
    
    self:runCsbAction("over")
    self.m_btn_up:setVisible(true)
    self.m_btn_down:setVisible(false)

    self.m_spot_title:findChild("sp_light_up"):setVisible(true)
    self.m_spot_title:findChild("sp_light_down"):setVisible(false)

    self:stopAllActions()

    self.m_mask:runCsbAction("animation2")

    performWithDelay(self,function(  )
        self.m_isWaitting = false
        self.m_mask:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end,30 / 60)
end

--[[
    刷新界面
]]
function DazzlingDiscoSpotView:refreshView()
    local collectData = self:getCollectsData()
    if not collectData then
        return
    end

    -- util_printTable(collectData)

    for i,spotData in ipairs(collectData) do
        local index = spotData.position + 1
        local item = self.m_spotItems[index]
        item:updateHead(spotData)
    end

    self:refreshTitleShow()
end

--[[
    刷新title显示
]]
function DazzlingDiscoSpotView:refreshTitleShow()
    local collectData = self:getCollectsData()
    if not collectData then
        return
    end
    local spotNum,playerCount = self:getPlayCountAndLeftSpot(collectData)
    self.m_spot_title:findChild("m_lb_spot"):setString(spotNum)
    self.m_spot_title:findChild("m_lb_players"):setString(playerCount)

    self.m_spot_title:findChild("Node_spot_num"):setVisible(spotNum > 0)
    self.m_spot_title:findChild("sp_bonus_start"):setVisible(spotNum == 0)
    self.m_spot_title:findChild("spot_left"):setVisible(spotNum == 1)
    self.m_spot_title:findChild("spots_left"):setVisible(spotNum > 1)
    self.m_spot_title:findChild("player_in"):setVisible(playerCount <= 1)
    self.m_spot_title:findChild("players_in"):setVisible(playerCount > 1)

    if spotNum <= 5 then
        if not self.m_spot_title.m_isIdle then
            self.m_spot_title.m_isIdle = true
            self.m_spot_title:runCsbAction("idle3",true)
        end
    else
        self.m_spot_title.m_isIdle = false
        self.m_spot_title:runCsbAction("idle1")
    end
end

--[[
    计算剩余spot点位以及玩家数量
]]
function DazzlingDiscoSpotView:getPlayCountAndLeftSpot(collectList)
    local playerList = {}
    local curCount,playerCount = 0,0
    for i,data in ipairs(collectList) do
        if data.udid ~= ""  then
            if not playerList[data.udid] then
                playerList[data.udid] = 1
                playerCount = playerCount + 1
            else
                playerList[data.udid] = playerList[data.udid] + 1
            end
            curCount = curCount + 1
        end
    end

    local playersInfo = self.m_machine.m_roomData:getRoomRanks() or {}

    return MAX_SPOT_COUNT - curCount,#playersInfo

end

--[[
    获取收集数据
]]
function DazzlingDiscoSpotView:getCollectsData()
    local spotResult = self.m_roomData:getSpotResult()
    local collectDatas = self.m_roomData:getRoomCollects()
    if spotResult then
        collectDatas = spotResult.data.collects
    end
    return collectDatas
end

--默认按钮监听回调
function DazzlingDiscoSpotView:clickFunc(sender)
    if self.m_isWaitting or not self.m_isTouchEnabled then
        return
    end
    
    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_UP then
        self:showView()
    elseif tag == BTN_TAG_DOWN then
        self:hideView()
    else
        self:refreshView()
        self:showAllPlayers()
    end
end

--[[
    设置按钮是否可点击
]]
function DazzlingDiscoSpotView:setBtnClickEnable(isEnabled)
    self.m_isTouchEnabled = isEnabled
    self.m_btn_down:setTouchEnabled(isEnabled)
    self.m_btn_up:setTouchEnabled(isEnabled)
    self.m_btn_show_players:setTouchEnabled(isEnabled)

    self.m_btn_down:setBright(isEnabled)
    self.m_btn_up:setBright(isEnabled)
end


--[[
    显示所有玩家
]]
function DazzlingDiscoSpotView:showAllPlayers()
    local playersInfo = self.m_machine.m_roomData:getRoomRanks()

    if #playersInfo == 0 then
        return
    end

    local view = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoAllPlayersView",{players = playersInfo})
    gLobalViewManager:showUI(view)

    view:setPosition(display.center)
end

return DazzlingDiscoSpotView