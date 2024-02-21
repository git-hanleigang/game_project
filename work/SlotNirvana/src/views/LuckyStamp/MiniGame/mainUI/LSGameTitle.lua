--2023
local LSGameTitle = class("LSGameTitle", BaseView)

function LSGameTitle:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_title.csb"
end

function LSGameTitle:initView()
    self:runCsbAction(
            "idle",
            true,
            function()
                -- if callFunc then
                --     callFunc()
                -- end
            end,
            60
        )
end

function LSGameTitle:initUI()
    LSGameTitle.super.initUI(self)

end

function LSGameTitle:onEnter()
    LSGameTitle.super.onEnter(self)
end

return LSGameTitle
