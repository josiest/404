Fragment = {}
function Fragment:new(ch)
    local fragment = {}
    setmetatable(fragment, self)
    self.__index = self
    fragment.char = ch
    fragment.center = {x=0, y=0}
    fragment.ul = {x=0, y=0}

    fragment.vel = {x=0, y=0}
    fragment.q = 5  -- "charge" for calculating acceleration

    -- so the letter knows where to return to when it breaks
    fragment.home = {x=0, y=0}

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

-- Parameters
mq = 10     -- mouse "charge" for calculating acceleration
ke = 5      -- "Coulomb's" constant
hc = 0.003  -- "home" constant - multiplier on force pushing letters home
uk = 0.002  -- "friction" coefficient

snap_radius = 3 -- pixel radius for the letter to snap back in place
vel_tol = 0.1  -- velocity tolerance for the letter to stop moving

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
        l.home.x = l.center.x

        -- increment the letter x-position
        x = x + buffer + w

        -- find height between top of line and top of letter
        local gap = link.height-h
        l.ul.y = link.y + gap
        l.center.y = l.ul.y + h/2
        l.home.y = l.center.y
    end
end

function love.mousepressed(x, y, button, istouch)
    if button == 1 and link.moused_over() and not link.is_broken then
        link.toggle_break()
    end
end

function link.moused_over()
    local x = love.mouse.getX()
    local y = love.mouse.getY()

    local x_in_range = x >= link.x and x <= link.x+link.width
    local y_in_range = y >= link.y and y <= link.y+link.height

    return x_in_range and y_in_range
end

function link.highlight()
    love.graphics.setLineWidth(4)

    local x0 = link.x
    local x1 = link.x + link.width
    local y = link.y + link.height

    love.graphics.line(x0, y, x1, y)
end

function love.draw()
    -- draw text
    love.graphics.setColor(link.color)
    for i, l in ipairs(link.letters) do
        love.graphics.print(l.char, l.ul.x, l.ul.y)
    end

    -- create underline for text to look like hyperlink
    -- specifically when mouse hovers over text
    if link.moused_over() and not link.is_broken then
        link.highlight()
        -- change cursor from arrow to hand when cursor enters text area
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        -- change cursor from hand to arrow when cursor leaves text area
        love.mouse.setCursor(love.mouse.getSystemCursor("arrow"))
    end

    local all_stoped = true
    -- move the characters away from the cursor if the link is broken
    if link.is_broken then
        for i, l in ipairs(link.letters) do

            -- difference vector between mouse click and character
            local dv = {
                x = -(love.mouse.getX() - l.center.x),
                y = -(love.mouse.getY() - l.center.y)
            }
            local dist = mag(dv)
            -- clamp dist so it doesn't get too small
            if dist < 0.01 then
                dist = 0.01
            end

            -- normalize difference vector
            dv.x = dv.x/dist
            dv.y = dv.y/dist

            -- "force" pushing the letter back home
            local dh = {
                x = l.home.x - l.center.x,
                y = l.home.y - l.center.y
            }
            local hdist = mag(dh)
            if hdist > 0 then
                dh.x = dh.x/hdist
                dh.y = dh.y/hdist
            else
                dh.x = 0
                dh.y = 0
            end

            -- accelerate the characters away from the mouse (Coulomb's Law)
            l.vel.x = l.vel.x + dv.x * ke*l.q*mq/(dist*dist)
            l.vel.y = l.vel.y + dv.y * ke*l.q*mq/(dist*dist)

            -- accelerate the characters toward home (Constant Force)
            l.vel.x = l.vel.x + hc*dh.x
            l.vel.y = l.vel.y + hc*dh.y

            -- apply "friction"
            l.vel.x = l.vel.x - uk*l.vel.x
            l.vel.y = l.vel.y - uk*l.vel.y

            -- reset the velocity to zero if within the tolerable
            -- range to home for distance and velocity
            if mag(l.vel) < vel_tol then --and hdist < snap_radius then
                l.vel.x = 0
                l.vel.y = 0
            else
                all_stopped = false
            end

            -- move the characters, but clamp them to the boundaries
            local new_cx = l.center.x + l.vel.x
            if new_cx >= 0 and new_cx <= width then
                l.ul.x = l.ul.x + l.vel.x
                l.center.x = new_cx
            else
                l.vel.x = 0
            end
            local new_cy = l.center.y + l.vel.y
            if new_cy >= 0 and new_cy <= height then
                l.ul.y = l.ul.y +l.vel.y
                l.center.y = new_cy
            else
                l.vel.y = 0
            end
        end
    end
    if all_stopped and link.is_broken then
        print("toggling break")
        link.toggle_break()
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
    return math.sqrt(vec.x*vec.x + vec.y*vec.y)
end
