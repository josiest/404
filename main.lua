Fragment = {
    char = "a", 
    pos = {0, 0},
}

function Fragment:new(ch)
    local fragment = {}
    setmetatable(fragment, self)
    self.__index = self
    fragment.char = ch
    return fragment
end

link = {
    text = "Utopia",
    letters = {},
    color = {0, 0, 1, 1}, -- blue to look like a hyperlink
    broken = false
}
for i = 1, #link.text do
    local c = link.text:sub(i, i)
    link.letters[i] = Fragment:new(c)
end

function love.load()
    -- set background to be white
    love.graphics.setBackgroundColor(1,1,1,1)

    -- global width and height
    width = love.graphics.getWidth()
    height = love.graphics.getHeight()

    -- font size will be used for all of the program
    love.graphics.setFont(love.graphics.newFont(50))

    -- global message
    link.font = love.graphics.getFont()
    link.width = link.font:getWidth(link.text)
    link.height = link.font:getHeight(link.text)
    link.x = (width-link.width)/2
    link.y = (height-link.height)/2

    -- Align all the fragments

    -- find the sum of raw width of the letters
    -- to find the spacing between them
    --frag_width = 0
    --for i = 0, #link.letters do
    --    frag_width = frag_width + link.font:getWidth(link.letters[i].char)
    --end
    --buffer = (link.width-fragwidth)/(#link.letters-1)

    --local x = link.x
    --for i = 0, #link.letters do
    --    link.letters[i].x = x
    --    x = x + buffer + link.font:getWidth(link.letters[i].char)
    --    link.letters[i] = link.y + (link.height-link.font:getHeight(link.letters[i]
    --end
end

function love.draw()
    link.print()
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 and link.hovering() and not link.broken then
        link.toggle_break()
    end
end

function link.hovering()
    local x = love.mouse.getX()
    local y = love.mouse.getY()

    return x >= link.x and x <= link.x+link.width and y >= link.y
           and y <= link.y+link.height
end

function link.print()
    -- draw text
    love.graphics.setColor(link.color)
    love.graphics.print(link.text, link.x, link.y)

    -- create underline for text to look like hyperlink
    -- specifically when mouse hovers over text
    if link.hovering() and not link.broken then
        love.graphics.setLineWidth(4)
        love.graphics.line(link.x, link.y+link.height,
                           link.x+link.width, link.y+link.height)

        -- change cursor from arrow to hand when cursor enters text area
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        -- change cursor from hand to arrow when cursor leaves text area
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end
end

function link.toggle_break()
    if not link.broken then
        link.color = {0, 0, 0, 1}
        link.broken = true
    else
        link.color = {0, 0, 1, 1}
        link.broken = false
    end
end
