--[[
    
    author:徐袁
    time:2021-03-28 12:52:40
]]
local BaseView = require("base.BaseView")
local StatuePickBigBox = class("StatuePickBigBox", BaseView)

function StatuePickBigBox:initUI()
    StatuePickBigBox.super.initUI(self)

    self:initView()
end

--[[
    @desc: 获取csb路径
    author:徐袁
    time:2021-03-28 12:52:40
    @return:
]]
function StatuePickBigBox:getCsbName()
    return "CardRes/season202102/Statue/StatueBigBox.csb"
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-28 12:52:40
    @return:
]]
function StatuePickBigBox:initCsbNodes()
    self.m_lvBoxs = {}
    self.m_lvBoxs["2"] = self:findChild("Lv2")
    self.m_lvBoxs["3"] = self:findChild("Lv3")
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-28 12:52:40
    @return:
]]
function StatuePickBigBox:initView()
    for k, v in pairs(self.m_lvBoxs) do
        v:setVisible(false)
    end
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-28 12:52:40
    @return:
]]
function StatuePickBigBox:updateView()
end

function StatuePickBigBox:setBoxLv(level)
    self.m_lvBoxs["" .. level]:setVisible(true)
end

function StatuePickBigBox:startAction(callback)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBigBoxAppear)    
    self:runCsbAction(
        "start",
        false,
        function()
            if callback then
                callback()
            end
        end
    )
end

function StatuePickBigBox:idleAction(callback)
    self:runCsbAction("idle", true)
end

function StatuePickBigBox:overAction(callback)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBigBoxDispersed)
    self:runCsbAction(
        "over",
        false,
        function()
            if callback then
                callback()
            end
        end
    )
end

return StatuePickBigBox
