--[[
    des：集卡赛季大厅 集卡小游戏
    author:{author}
    time:2019-12-23 14:28:18
]]
local CardSeasonCellPuzzleHouse = class("CardSeasonCellPuzzleHouse", BaseView)

-- 初始化UI --
function CardSeasonCellPuzzleHouse:initUI()
    CardSeasonCellPuzzleHouse.super.initUI(self)
    self:initView()
end

function CardSeasonCellPuzzleHouse:getCsbName()
    return CardResConfig.CardSeasonCellPizzleHouseRes
end

function CardSeasonCellPuzzleHouse:initCsbNodes()
    self.m_nodeSpine = self:findChild("Node_spine")
    self.m_nodePaly = self:findChild("Node_paly")
    self.m_nodeTime = self:findChild("Node_time")
    self.m_btnQuestion = self:findChild("Button_wenhao")
end

function CardSeasonCellPuzzleHouse:initView()
    local spine1 = util_spineCreate("CardRes/spine/DwarfFairy_Standing", false, true, 1)
    self.m_nodeSpine:addChild(spine1)
    util_spinePlay(spine1, "ildeframe", true)
    spine1:setPosition(cc.p(60, -310))

    local spine2 = util_spineCreate("CardRes/spine/CSG_LobbyLayer_Xiaoaixian", false, true, 1)
    self.m_nodeSpine:addChild(spine2, 0)
    util_spinePlay(spine2, "idle", true)
    spine2:setPosition(cc.p(0, -310))

    self:checkSeasonTimeOut()
end

function CardSeasonCellPuzzleHouse:checkSeasonTimeOut()
    if true then
        self.m_nodePaly:setVisible(false)
        self.m_nodeTime:setVisible(false)
        self.m_btnQuestion:setVisible(false)
    end
end

function CardSeasonCellPuzzleHouse:updateHouse(seasonId)
end

return CardSeasonCellPuzzleHouse
