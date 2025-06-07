-- Matcha Latte UI Library
local UILib = {}
UILib.__index = UILib

-- Helper functions
local function clamp(value, min, max)
    if value < min then return min
    elseif value > max then return max
    else return value end
end

local function rgb(r, g, b)
    return Color3(r/255, g/255, b/255)
end

local function getMousePos()
    return Vector2(0, 0) -- Placeholder - would use actual mouse position
end

-- Color constants
local COLORS = {
    BACKGROUND = rgb(20, 20, 20),
    ACCENT = rgb(106, 0, 255),
    SECONDARY = rgb(30, 30, 30),
    TEXT = rgb(255, 255, 255),
    BUTTON = rgb(40, 40, 40),
    BUTTON_HOVER = rgb(50, 50, 50),
    INPUT = rgb(40, 40, 40)
}

-- Z-Index constants
local Z_INDEX = {
    BASE = 1000,
    WINDOW = 2000,
    CONTROLS = 3000,
    DROPDOWN_BASE = 8000,
    DROPDOWN_OPTIONS = 9000,
    COLOR_PICKER = 10000
}

-- Key codes for input
local KEY_CODES = {
    K = 0x4B,
    ESCAPE = 0x1B,
    ENTER = 0x0D,
    BACKSPACE = 0x08
}

-- Global state
local isVisible = true
local isMouseDown = false
local mouseClicked = false

-- HSV color conversion
local function hsvToRgb(h, s, v)
    if s <= 0 then return v, v, v end
    h = h * 6
    local c = v * s
    local x = c * (1 - math.abs(h % 2 - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    
    if h < 1 then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else r, g, b = c, 0, x end
    
    return r + m, g + m, b + m
end

local function rgbToHsv(r, g, b)
    r, g, b = r/255, g/255, b/255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min
    local h, s, v = 0, 0, max
    
    if max == 0 then s = 0
    else s = delta / max end
    
    if delta == 0 then h = 0
    else
        if max == r then h = (g - b) / delta
            if g < b then h = h + 6 end
        elseif max == g then h = (g - b) / delta + 2
        else h = (r - g) / delta + 4 end
        h = h / 6
    end
    
    return h, s, v
end

-- Window creation
function UILib:CreateWindow(config)
    local self = setmetatable({}, UILib)
    self.tabs = {}
    self.activeTab = nil
    self.name = config.Name or "Example Window"
    self.minimized = false
    
    -- Main window background
    self.base = Drawing.new("Square")
    self.base.Size = Vector2(600, 350)
    self.base.Position = Vector2(200, 200)
    self.base.Filled = true
    self.base.Color = COLORS.BACKGROUND
    self.base.Visible = isVisible
    self.base.Corner = 7
    self.base.ZIndex = Z_INDEX.WINDOW
    
    -- Title text
    self.title = Drawing.new("Text")
    self.title.Text = self.name
    self.title.Position = Vector2(210, 210)
    self.title.Color = COLORS.TEXT
    self.title.Visible = isVisible
    self.title.ZIndex = Z_INDEX.WINDOW + 1
    
    -- Close button lines
    self.closeLine1 = Drawing.new("Line")
    self.closeLine1.From = Vector2(775, 210)
    self.closeLine1.To = Vector2(790, 225)
    self.closeLine1.Color = COLORS.TEXT
    self.closeLine1.Thickness = 2
    self.closeLine1.Visible = isVisible
    self.closeLine1.ZIndex = Z_INDEX.WINDOW + 1
    
    self.closeLine2 = Drawing.new("Line")
    self.closeLine2.From = Vector2(775, 225)
    self.closeLine2.To = Vector2(790, 210)
    self.closeLine2.Color = COLORS.TEXT
    self.closeLine2.Thickness = 2
    self.closeLine2.Visible = isVisible
    self.closeLine2.ZIndex = Z_INDEX.WINDOW + 1
    
    -- Minimize line
    self.minimizeLine = Drawing.new("Line")
    self.minimizeLine.From = Vector2(745, 217)
    self.minimizeLine.To = Vector2(760, 217)
    self.minimizeLine.Color = COLORS.TEXT
    self.minimizeLine.Thickness = 2
    self.minimizeLine.Visible = isVisible
    self.minimizeLine.ZIndex = Z_INDEX.WINDOW + 1
    
    function self:CreateTab(name)
        local tabIndex = #self.tabs + 1
        local tabY = 250 + (tabIndex - 1) * 40
        
        -- Tab background
        local tab = Drawing.new("Square")
        tab.Size = Vector2(100, 30)
        tab.Position = Vector2(210, tabY)
        tab.Filled = true
        tab.Color = COLORS.SECONDARY
        tab.Visible = isVisible
        tab.Corner = 5
        tab.ZIndex = Z_INDEX.CONTROLS
        
        -- Tab label
        local label = Drawing.new("Text")
        label.Text = name or "Example Tab"
        label.Position = Vector2(220, tabY + 8)
        label.Color = COLORS.TEXT
        label.Visible = isVisible
        label.ZIndex = Z_INDEX.CONTROLS + 1
        
        -- Tab indicator
        local indicator = Drawing.new("Square")
        indicator.Size = Vector2(7, 20)
        indicator.Position = Vector2(210, tabY + 5)
        indicator.Filled = true
        indicator.Color = COLORS.ACCENT
        indicator.Visible = tabIndex == 1
        indicator.Corner = 5
        indicator.ZIndex = Z_INDEX.CONTROLS + 1
        
        local tabObj = {
            index = tabIndex,
            name = name or "Example Tab",
            tab = tab,
            label = label,
            indicator = indicator,
            items = {}
        }
        
        -- Tab methods
        function tabObj:CreateButton(config)
            return self:CreateButton(tabObj, config.Name, config.Callback)
        end
        
        function tabObj:CreateToggle(config)
            return self:CreateToggle(tabObj, config.Name, config.CurrentValue, config.Callback)
        end
        
        function tabObj:CreateSlider(config)
            return self:CreateSlider(tabObj, config.Name, config.Range[1], config.Range[2], 
                                   config.CurrentValue, config.Increment, config.Callback)
        end
        
        function tabObj:CreateDropdown(config)
            return self:CreateDropdown(tabObj, config.Name, config.Options, 
                                     config.CurrentOption[1], config.Callback, config.MultipleOptions)
        end
        
        function tabObj:CreateTextbox(config)
            return self:CreateTextbox(tabObj, config.Name, config.Default, 
                                    config.PlaceholderText, config.ClearTextOnFocus, config.Callback)
        end
        
        function tabObj:CreateColorPicker(config)
            return self:CreateColorPicker(tabObj, config.Name, config.Default, config.Callback)
        end
        
        table.insert(self.tabs, tabObj)
        if not self.activeTab then
            self.activeTab = tabObj
        end
        
        return tabObj
    end
    
    return self
end

-- Button component
function UILib:CreateButton(tab, name, callback)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    -- Button container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Button label
    local label = Drawing.new("Text")
    label.Text = name or "Example Button"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    local button = {
        type = "button",
        container = container,
        label = label,
        callback = callback,
        text = name or "Example Button"
    }
    
    table.insert(tab.items, button)
    return button
end

-- Toggle component
function UILib:CreateToggle(tab, name, currentValue, callback)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    -- Toggle container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Toggle checkbox
    local box = Drawing.new("Square")
    box.Size = Vector2(20, 20)
    box.Position = Vector2(720, itemY + 7)
    box.Filled = true
    box.Color = COLORS.SECONDARY
    box.Visible = isVisible
    box.Corner = 3
    box.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Toggle fill
    local fill = Drawing.new("Square")
    fill.Size = Vector2(16, 16)
    fill.Position = Vector2(722, itemY + 9)
    fill.Filled = true
    fill.Color = COLORS.ACCENT
    fill.Visible = isVisible and (currentValue or false)
    fill.Corner = 2
    fill.ZIndex = Z_INDEX.CONTROLS + 2
    
    -- Toggle label
    local label = Drawing.new("Text")
    label.Text = name or "Example Toggle"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    local toggle = {
        type = "toggle",
        container = container,
        box = box,
        fill = fill,
        label = label,
        state = currentValue or false,
        callback = callback,
        text = name or "Example Toggle"
    }
    
    table.insert(tab.items, toggle)
    return toggle
end

-- Slider component
function UILib:CreateSlider(tab, name, min, max, currentValue, increment, callback)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    -- Slider container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Slider bar
    local bar = Drawing.new("Square")
    bar.Size = Vector2(120, 10)
    bar.Position = Vector2(600, itemY + 12)
    bar.Filled = true
    bar.Color = COLORS.SECONDARY
    bar.Visible = isVisible
    bar.Corner = 3
    bar.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Slider fill
    local fill = Drawing.new("Square")
    local fillWidth = ((currentValue or min) - min) / (max - min) * 120
    fill.Size = Vector2(fillWidth, 10)
    fill.Position = Vector2(600, itemY + 12)
    fill.Filled = true
    fill.Color = COLORS.ACCENT
    fill.Visible = isVisible
    fill.Corner = 3
    fill.ZIndex = Z_INDEX.CONTROLS + 2
    
    -- Slider indicator
    local indicator = Drawing.new("Square")
    indicator.Size = Vector2(10, 16)
    indicator.Position = Vector2(600 + fillWidth - 5, itemY + 10)
    indicator.Filled = true
    indicator.Color = COLORS.ACCENT
    indicator.Visible = isVisible
    indicator.Corner = 3
    indicator.ZIndex = Z_INDEX.CONTROLS + 3
    
    -- Slider label
    local label = Drawing.new("Text")
    label.Text = name or "Example Slider"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Value label
    local valueLabel = Drawing.new("Text")
    valueLabel.Text = tostring(currentValue or min)
    valueLabel.Position = Vector2(730, itemY + 8)
    valueLabel.Color = COLORS.TEXT
    valueLabel.Visible = isVisible
    valueLabel.ZIndex = Z_INDEX.CONTROLS + 1
    
    local slider = {
        type = "slider",
        container = container,
        bar = bar,
        fill = fill,
        indicator = indicator,
        label = label,
        valueLabel = valueLabel,
        min = min or 0,
        max = max or 100,
        value = currentValue or min or 0,
        step = increment or 1,
        callback = callback,
        text = name or "Example Slider"
    }
    
    table.insert(tab.items, slider)
    return slider
end

-- Dropdown component
function UILib:CreateDropdown(tab, name, options, currentOption, callback, multipleOptions)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    -- Dropdown container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Dropdown label
    local label = Drawing.new("Text")
    label.Text = name or "Example Dropdown"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Preview box
    local previewBox = Drawing.new("Square")
    previewBox.Size = Vector2(120, 24)
    previewBox.Position = Vector2(620, itemY + 5)
    previewBox.Filled = true
    previewBox.Color = COLORS.SECONDARY
    previewBox.Visible = isVisible
    previewBox.Corner = 5
    previewBox.ZIndex = Z_INDEX.CONTROLS + 2
    
    -- Selection text
    local selectionText = Drawing.new("Text")
    selectionText.Text = currentOption or (options and options[1]) or "Example"
    selectionText.Position = Vector2(630, itemY + 9)
    selectionText.Color = COLORS.TEXT
    selectionText.Visible = isVisible
    selectionText.ZIndex = Z_INDEX.CONTROLS + 3
    
    -- Dropdown container (when opened)
    local dropdownContainer = Drawing.new("Square")
    dropdownContainer.Size = Vector2(200, 200)
    dropdownContainer.Position = Vector2(760, itemY)
    dropdownContainer.Filled = true
    dropdownContainer.Color = COLORS.BACKGROUND
    dropdownContainer.Visible = false
    dropdownContainer.Corner = 5
    dropdownContainer.ZIndex = Z_INDEX.DROPDOWN_BASE
    
    -- Create option elements
    local optionElements = {}
    if options then
        for i, option in ipairs(options) do
            local optionBg = Drawing.new("Square")
            optionBg.Size = Vector2(190, 25)
            optionBg.Position = Vector2(765, itemY + 35 + (i-1) * 30)
            optionBg.Filled = true
            optionBg.Color = COLORS.SECONDARY
            optionBg.Visible = false
            optionBg.Corner = 5
            optionBg.ZIndex = Z_INDEX.DROPDOWN_OPTIONS + i * 2
            
            local optionText = Drawing.new("Text")
            optionText.Text = tostring(option)
            optionText.Position = Vector2(775, itemY + 42 + (i-1) * 30)
            optionText.Color = COLORS.TEXT
            optionText.Visible = false
            optionText.ZIndex = Z_INDEX.DROPDOWN_OPTIONS + i * 2 + 1
            
            table.insert(optionElements, {
                background = optionBg,
                label = optionText,
                text = option,
                isHovered = false,
                selected = false
            })
        end
    end
    
    local dropdown = {
        type = "dropdown",
        container = container,
        label = label,
        previewBox = previewBox,
        selectionText = selectionText,
        dropdownContainer = dropdownContainer,
        options = optionElements,
        callback = callback,
        currentOption = currentOption or (options and options[1]) or "Example",
        selectedOptions = {},
        isOpen = false,
        text = name or "Example Dropdown",
        multipleOptions = multipleOptions or false
    }
    
    table.insert(tab.items, dropdown)
    return dropdown
end

-- Textbox component
function UILib:CreateTextbox(tab, name, default, placeholder, clearOnFocus, callback)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    -- Textbox container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Textbox label
    local label = Drawing.new("Text")
    label.Text = name or "Example Textbox"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Input box
    local inputBox = Drawing.new("Square")
    inputBox.Size = Vector2(120, 24)
    inputBox.Position = Vector2(620, itemY + 5)
    inputBox.Filled = true
    inputBox.Color = COLORS.INPUT
    inputBox.Visible = isVisible
    inputBox.Corner = 5
    inputBox.ZIndex = Z_INDEX.CONTROLS + 2
    
    -- Input text
    local inputText = Drawing.new("Text")
    inputText.Text = default or "Example Text"
    inputText.Position = Vector2(630, itemY + 9)
    inputText.Color = COLORS.TEXT
    inputText.Visible = isVisible
    inputText.ZIndex = Z_INDEX.CONTROLS + 3
    
    local textbox = {
        type = "textbox",
        container = container,
        label = label,
        inputBox = inputBox,
        inputText = inputText,
        text = name or "Example Textbox",
        value = default or "Example Text",
        placeholder = placeholder or "Type here...",
        clearOnFocus = clearOnFocus or false,
        callback = callback,
        isFocused = false
    }
    
    table.insert(tab.items, textbox)
    return textbox
end

-- Color Picker component
function UILib:CreateColorPicker(tab, name, default, callback)
    local itemIndex = #tab.items + 1
    local itemY = 300 + (itemIndex - 1) * 40
    
    local defaultColor = default or rgb(255, 0, 0)
    
    -- Color picker container
    local container = Drawing.new("Square")
    container.Size = Vector2(420, 35)
    container.Position = Vector2(330, itemY)
    container.Filled = true
    container.Color = COLORS.BUTTON
    container.Visible = isVisible
    container.Corner = 5
    container.ZIndex = Z_INDEX.CONTROLS
    
    -- Color picker label
    local label = Drawing.new("Text")
    label.Text = name or "Example Color Picker"
    label.Position = Vector2(340, itemY + 8)
    label.Color = COLORS.TEXT
    label.Visible = isVisible
    label.ZIndex = Z_INDEX.CONTROLS + 1
    
    -- Preview box
    local previewBox = Drawing.new("Square")
    previewBox.Size = Vector2(24, 24)
    previewBox.Position = Vector2(716, itemY + 5)
    previewBox.Filled = true
    previewBox.Color = defaultColor
    previewBox.Visible = isVisible
    previewBox.Corner = 5
    previewBox.ZIndex = Z_INDEX.CONTROLS + 2
    
    -- Color picker container (when opened)
    local pickerContainer = Drawing.new("Square")
    pickerContainer.Size = Vector2(200, 250)
    pickerContainer.Position = Vector2(760, itemY)
    pickerContainer.Filled = true
    pickerContainer.Color = COLORS.BACKGROUND
    pickerContainer.Visible = false
    pickerContainer.Corner = 5
    pickerContainer.ZIndex = Z_INDEX.COLOR_PICKER
    
    -- Selected color preview
    local selectedColorPreview = Drawing.new("Square")
    selectedColorPreview.Size = Vector2(180, 40)
    selectedColorPreview.Position = Vector2(770, itemY + 45)
    selectedColorPreview.Filled = true
    selectedColorPreview.Color = defaultColor
    selectedColorPreview.Visible = false
    selectedColorPreview.Corner = 5
    selectedColorPreview.ZIndex = Z_INDEX.COLOR_PICKER + 1
    
    -- Hue gradient
    local hueGradient = Drawing.new("Square")
    hueGradient.Size = Vector2(180, 25)
    hueGradient.Position = Vector2(770, itemY + 95)
    hueGradient.Filled = true
    hueGradient.Color = rgb(255, 0, 0)
    hueGradient.Visible = false
    hueGradient.Corner = 5
    hueGradient.ZIndex = Z_INDEX.COLOR_PICKER + 1
    
    -- Saturation gradient
    local saturationGradient = Drawing.new("Square")
    saturationGradient.Size = Vector2(180, 25)
    saturationGradient.Position = Vector2(770, itemY + 130)
    saturationGradient.Filled = true
    saturationGradient.Color = rgb(255, 0, 0)
    saturationGradient.Visible = false
    saturationGradient.Corner = 5
    saturationGradient.ZIndex = Z_INDEX.COLOR_PICKER + 1
    
    -- Value gradient
    local valueGradient = Drawing.new("Square")
    valueGradient.Size = Vector2(180, 25)
    valueGradient.Position = Vector2(770, itemY + 165)
    valueGradient.Filled = true
    valueGradient.Color = rgb(255, 0, 0)
    valueGradient.Visible = false
    valueGradient.Corner = 5
    valueGradient.ZIndex = Z_INDEX.COLOR_PICKER + 1
    
    local r, g, b = defaultColor.r * 255, defaultColor.g * 255, defaultColor.b * 255
    local h, s, v = rgbToHsv(r, g, b)
    
    local colorPicker = {
        type = "colorpicker",
        container = container,
        label = label,
        previewBox = previewBox,
        pickerContainer = pickerContainer,
        selectedColorPreview = selectedColorPreview,
        hueGradient = hueGradient,
        saturationGradient = saturationGradient,
        valueGradient = valueGradient,
        callback = callback,
        currentColor = defaultColor,
        isOpen = false,
        text = name or "Example Color Picker",
        hue = h or 0,
        saturation = s or 1,
        value = v or 1,
        hueSegments = {},
        saturationSegments = {},
        valueSegments = {}
    }
    
    function colorPicker:UpdateColor()
        local r, g, b = hsvToRgb(self.hue, self.saturation, self.value)
        r = math.floor(r * 255)
        g = math.floor(g * 255)
        b = math.floor(b * 255)
        self.currentColor = rgb(r, g, b)
        self.previewBox.Color = self.currentColor
        self.selectedColorPreview.Color = self.currentColor
        if self.callback then
            self.callback(self.currentColor)
        end
    end
    
    table.insert(tab.items, colorPicker)
    return colorPicker
end

-- Main update function
function UILib:Step()
    -- Handle toggle key (K by default)
    if iskeypressed(KEY_CODES.K) then
        isVisible = not isVisible
        self:UpdateVisibility()
    end
    
    -- Handle mouse input
    mouseClicked = false
    if ismouse1pressed then
        if not isMouseDown then
            mouseClicked = true
        end
        isMouseDown = true
    else
        isMouseDown = false
    end
end

function UILib:UpdateVisibility()
    -- Update all UI elements visibility
    self.base.Visible = isVisible
    self.title.Visible = isVisible
    self.closeLine1.Visible = isVisible
    self.closeLine2.Visible = isVisible
    self.minimizeLine.Visible = isVisible
    
    for _, tab in ipairs(self.tabs) do
        local tabVisible = isVisible and not self.minimized
        tab.tab.Visible = tabVisible
        tab.label.Visible = tabVisible
        tab.indicator.Visible = tabVisible and tab == self.activeTab
        
        for _, item in ipairs(tab.items) do
            local itemVisible = tabVisible and tab == self.activeTab
            if item.container then item.container.Visible = itemVisible end
            if item.label then item.label.Visible = itemVisible end
            if item.box then item.box.Visible = itemVisible end
            if item.fill then item.fill.Visible = itemVisible and item.state end
            if item.bar then item.bar.Visible = itemVisible end
            if item.indicator then item.indicator.Visible = itemVisible end
            if item.valueLabel then item.valueLabel.Visible = itemVisible end
            if item.previewBox then item.previewBox.Visible = itemVisible end
            if item.selectionText then item.selectionText.Visible = itemVisible end
            if item.inputBox then item.inputBox.Visible = itemVisible end
            if item.inputText then item.inputText.Visible = itemVisible end
        end
    end
end

return UILib
