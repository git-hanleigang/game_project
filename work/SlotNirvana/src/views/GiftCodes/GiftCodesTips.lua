local GiftCodesTips = class("GiftCodesTips", BaseView)

function GiftCodesTips:initUI(_type)
    local path = "Activity_GiftCodes/Activity/csb/Activity_GiftCodes_Tip.csb"
    self.m_type = _type
    self:createCsbNode(path)
    self:initView()
end

function GiftCodesTips:initCsbNodes()
end

function GiftCodesTips:initView()
    for i=1,4 do
        self:findChild("lb_desc_"..i):setVisible(i == self.m_type)
    end
    self:showAction()
end

function GiftCodesTips:showAction()
    self:runCsbAction(
        "start",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self:runCsbAction("over",false,function()
                        self.status = true
                    end)
                end,
                2
            )
        end
    )
end

return GiftCodesTips