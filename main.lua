Fragment = {}
function Fragment:new(ch)
    local fragment = {}
    setmetatable(fragment, self)
    self.__index = self
    fragment.char = ch
    fragment.center = {x=0, y=0}
    fragment.ul = {x=0, y=0}
    fragment.vel = {x=0, y=0}
    fragment.q = 1  -- "charge" for calculating acceleration
    return fragment
end

link = {
    text = "Utopia",
    letters = {},
    color = {0, 0, 1, 1}, -- blue to look like a hyperlink
    is_broken = false
}
for i = 1, #link.text do
    local c = link.text:sub(i, i)
    local f = Fragment:new(c)
    link.letters[i] = f
end

mq = 5 -- mouse "charge" for calculating acceleration
ke = 1 -- "Coulomb's" constant

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
    frag_width = 0
    for i = 1, #link.letters do
        frag_width = frag_width + link.font:getWidth(link.letters[i].char)
    end
    buffer = (link.width-frag_width)/(#link.letters-1)

    -- assign a position to each letter
    local x = link.x
    for i, l in ipairs(link.letters) do
        local w = link.font:getWidth(l.char)
        local h = link.font:getHeight(l.char)

        -- set the center and upper-left corner x positions
        l.ul.x = x
        l.center.x = x + w/2

        -- increment the letter x-position
        x = x + buffer + w

        -- find height between top of line and top of letter
        local gap = link.height-h
        l.ul.y = link.y + gap
        l.center.y = l.ul.y + h/2
    end
end

function love.draw()
    link.draw()

    if link.is_broken then
        for _, l in ipairs(link.letters) do
            l.ul.x = l.ul.x + l.vel.x
            l.ul.y = l.ul.y + l.vel.y
            l.center.x = l.center.x + l.vel.x
            l.center.y = l.center.y + l.vel.y
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 and link.hovering() and not link.is_broken then
        link.toggle_break()
    end
end

function link.hovering()
    local x = love.mouse.getX()
    local y = love.mouse.getY()

    return x >= link.x and x <= link.x+link.width and y >= link.y
           and y <= link.y+link.height
end

function link.draw()
    -- draw text
    love.graphics.setColor(link.color)
    for i, l in ipairs(link.letters) do
        love.graphics.print(l.char, l.ul.x, l.ul.y)
    end

    -- create underline for text to look like hyperlink
    -- specifically when mouse hovers over text
    if link.hovering() and not link.is_broken then
        love.graphics.setLineWidth(4)
        love.graphics.line(link.x, link.y+link.height,
                           link.x+link.width, link.y+link.height)

        -- change cursor from arrow to hand when cursor enters text area
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        -- change cursor from hand to arrow when cursor leaves text area
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end

    -- move the characters away from the cursor if the link is broken
    if link.is_broken then
        for i, l in ipairs(link.letters) do

            -- difference vector between mouse click and character
            local dv = {
                x = love.mouse.getX() - l.center.x,
                y = love.mouse.getY() - l.center.y
            }
            local dist = mag(dv)

            -- normalize difference vector
            dv.x = dv.x/dist
            dv.y = dv.y/dist

            -- accelerate the characters
            l.vel.x = l.vel.x + dv.x * ke*l.q*mq/(dist*dist)
            l.vel.y = l.vel.y + dv.y * ke*l.q*mq/(dist*dist)

            -- move the characters
            l.ul.x = l.ul.x + l.vel.x
            l.ul.y = l.ul.y + l.vel.y
            l.center.x = l.center.x + l.vel.x
            l.center.y = l.center.y + l.vel.y

            -- clamp the characters
            if l.center.x < 0 then
                l.center.x = 0
                l.ul.x = -link.font:getWidth(l.char)/2
            end if l.center.x > width then
                l.center.x = width
                l.ul.x = width-link.font:getWidth(l.char)/2
            end

            if l.center.y < 0 then
                l.center.y = 0
                l.ul.y = -link.font:getHeight(l.char)/2
            end if l.center.y > height then
                l.center.y = height
                l.ul.y = height-link.font:getHeight(l.char)/2
            end
        end
    end
end

function link.toggle_break()
    if not link.is_broken then
        link.color = {0, 0, 0, 1}
        link.is_broken = true
    else
        link.color = {0, 0, 1, 1}
        link.is_broken = false
    end
end

function mag(vec)
    return math.sqrt(vec.x*vec.x + vec.y+vec.y)
end
