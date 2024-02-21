--[[--
    二级折叠菜单组

    构造：
    local groupData = {
        {
            title = '分类1',
            isTitle = true,
            items = {
                { id = 1, count = 20, lv = 19 },
                { id = 2, count = 21, lv = 21 },
                { id = 3, count = 22, lv = 23 },
            }
        },
        {
            title = '图腾',
            isTitle = true,
            items = {
                { id = 500001, count = 32, lv = 19 },
                { id = 500002, count = 21, lv = 65 },
                { id = 500003, count = 22, lv = 27 },
            }
        },
        {
            title = '武器',
            isTitle = true,
            items = {
                { id = 101002, count = 20, lv = 45 },
                { id = 101003, count = 21, lv = 34 },
            }
        },
        {
            title = '',
            isTitle = false,
            items = {
                { id = 101002, count = 20, lv = 45 },
                { id = 101003, count = 21, lv = 34 },
            }
        }
    }
    self._goodsCateList = UIMenuList.new( cc.size( 310, 510 ), groupData )
    
    -- 可选参数，是否可同时展开多个分组，默认false
    self._goodsCateList._showMulti = true

    @author maqun    
]]
local UIMenuList = class(
    "UIMenuList", 
    function() 
        return cc.Node:create()
    end
)

function UIMenuList:ctor(_size, _groupDataList)

    self.m_size = _size
    assert(self.m_size ~= nil, "_size is nil")
    
    -- 分组的数据
    self.m_groupDataList = _groupDataList
    assert(self.m_groupDataList ~= nil, "_groupDataList is nil")

    self.m_displayList = {} -- 展开的组
    
    self.m_itemPosList = {} -- 记录每个item的位置
    self.m_groupHeightList = {} -- 记录每个组的高度
    self.m_groupItemList = {} -- 记录每个组的items

    self:createScrollView()
end

function UIMenuList:createScrollView()
    local sv = ccui.ScrollView:create()

    sv:setContentSize(self.m_size)
    sv:setAnchorPoint(0, 0)
    sv:setDirection(ccui.ScrollViewDir.vertical)
    sv:setBounceEnabled(false)
    sv:setScrollBarEnabled(false)

    -- for i=1,10 do
    --     local sp = cc.Sprite:create("dlrb.png")
    --     sv:addChild(sp)
    --     sp:setPosition(cc.p(i*350, size.height/2))
    -- end

    -- sv:setInnerContainerSize({width = 4000, height = size.height})
    -- sv:setPosition(640,360)

    self.m_scrollView = sv
    self:addChild(sv)
end



return UIMenuList