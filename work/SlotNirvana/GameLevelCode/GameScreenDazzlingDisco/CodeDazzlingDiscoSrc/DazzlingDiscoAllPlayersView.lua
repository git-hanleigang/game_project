---
--xcyy
--2018年5月23日
--DazzlingDiscoAllPlayersView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoAllPlayersView = class("DazzlingDiscoAllPlayersView",util_require("Levels.BaseLevelDialog"))

function DazzlingDiscoAllPlayersView:initUI(params)
    local playerList = params.players or {}
    self:createCsbNode("DazzlingDisco_base_spottouxiang_0.csb")

    self:findChild("m_lb_num"):setString(#playerList)

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:findChild("Node_mask"):addChild(self.m_mask)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_all_players)
    self.m_mask:runCsbAction("animation0")
    self:runCsbAction("start")

    --摆成4*4
    local panel = self:findChild("Panel_1")
    local size = panel:getContentSize()
    local headWidth = size.width / 4
    local headHeight = size.height / 4

    local playerCount = #playerList
    if playerCount >= 16 then
        playerCount = 16
    end

    self.m_headItems = {}
    for index = 1,playerCount do
        
        local item = util_createView("CodeDazzlingDiscoSrc.DazzlingDiscoSpotHeadItem",{index = index,parent = self})
        panel:addChild(item)
        item:runCsbAction("idle")
        self.m_headItems[#self.m_headItems + 1] = item

        local colIndex = index % 4
        if colIndex == 0 then
            colIndex = 4
        end

        local rowIndex = math.ceil(index / 4) 

        local posX = headWidth / 2 + (colIndex - 1) * headWidth
        local posY = size.height - (headHeight / 2 + (rowIndex - 1) * headHeight) 
        item:setPosition(cc.p(posX,posY))

        local playerData = playerList[index]
        item:updateHead(playerData)
        item:findChild("Node_coins"):setVisible(false)

        item:findChild("banzi"):setVisible(true)

        local txt_name = item:findChild("txt_name")
        txt_name:setString(playerData.nickName or "")
        txt_name:stopAllActions()
        
        local clipNode = txt_name:getParent()
        local clipSize = clipNode:getContentSize()
        txt_name:setAnchorPoint(cc.p(0.5,0.5))
        txt_name:setPosition(cc.p(clipSize.width / 2,clipSize.height / 2))

        util_wordSwing(txt_name, 1, clipNode, 2, 30, 2)
    end
end

--默认按钮监听回调
function DazzlingDiscoAllPlayersView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    self.m_isClicked = true
    local name = sender:getName()
    local tag = sender:getTag()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_hide_all_players)
    self.m_mask:runCsbAction("animation2")
    self:runCsbAction("over",false,function()
        self:removeFromParent()
    end)

    
end

--[[
    计算剩余spot点位以及玩家数量
]]
function DazzlingDiscoAllPlayersView:getPlayCountAndLeftSpot(collectList)

    local playersInfo = self.m_machine.m_roomData:getRoomRanks() or {}

    return #playersInfo

end

return DazzlingDiscoAllPlayersView