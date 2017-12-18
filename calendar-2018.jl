using Luxor

pentagon(pos, radius, ang=0, action=:stroke) = ngon(pos, radius, 5, ang, vertices=true)

function drawmonth(year, month, radius)
    # origin is now in center of pentagon
    @layer begin
        rotate(pi)
        fontsize(18)
        fontface("DINNextLTPro-Black")
        text(string(Dates.monthname(Date(year, month, 1))), Point(0, -radius/2 + 5), halign=:center)
        translate(0, radius/6 - 5)
        lengthofmonth = Dates.daysinmonth(Date(year, month, 1))
        days = Tiler(radius + 30, radius + 10, 6, 7)  # 6 is max poss weeks
        pts = map(first, collect(days))
        # In Europe, first day of week (and first column) is Monday
        # Find difference between first Monday of month
        # and day 1 of month, then shift to first column
        # In the US, if Sunday is first column, use 9 not 8
        doff = mod1(8 - Dates.day(Dates.tofirst(Date(year, month, 1), 1)), 7)
        fontsize(9)
        fontface("Georgia-Bold")
        for d in 1:lengthofmonth
            # different colour for weekends
            # In Europe
            (d + doff + 1) % 7 < 2 ? sethue("purple") : sethue("black") # weekend
            # In US, don't add that 1
            pt = pts[d + doff]
            text(string(d), pt, halign=:center)
        end
        # add julia logo
        translate(0, radius/1.7)
        juliacircles(2)
    end
end

function drawflaps(radius, initrot, flapwidth, month)
    # initrot is non 0 when it's the center pentagon
    @layer begin
        if initrot == 0.0
            flapsideinner = pentagon(O, radius, deg2rad(108/2))[2:5]
            flapsideouter = pentagon(O, radius + flapwidth, deg2rad(108/2))[2:5]
            month < 6 ? edge = 1 : edge = 2
            for flap in [edge, 3]
                startflap   = flapsideinner[flap]
                flapcorner1 = between(flapsideouter[flap], flapsideouter[flap + 1], .2)
                flapcorner2 = between(flapsideouter[flap], flapsideouter[flap + 1], .7)
                endflap     = flapsideinner[flap + 1]
                poly([startflap, flapcorner1, flapcorner2, endflap], :stroke)
            end
        end
    end
end

function domonth(pt, radius, year, month;
        initrot = 0,
        flapwidth = 25,
        img = "")
    println("drawing: $year $month")
    rot = slope(O, pt)
    @layer begin
        setopacity(0.5)
        translate(pt)
        rotate(initrot)
        if img != ""
            @layer begin
                im = readpng(img)
                rotate(rot - pi/2)
                ngon(O, radius, 5, pi/10, :clip)
                scale(0.25)
                placeimage(im, O, 0.25, centered=true)
                clipreset()
            end
        end
        # poss bug, this is needed after image transparency:
        setopacity(1.0)
        poly(pentagon(O, radius), :stroke, close=true)
        # rotate ready for text entry:
        rotate(rot + pi/2)
        drawmonth(year, month, radius)
        drawflaps(radius, initrot, flapwidth, month)
    end
end

function draw6months(fname, year, month, radius;
        img = "")
    Drawing("A", fname)
    origin()
    background("white")
    sethue("black")
    setline(0.15)
    pcenters = pentagon(O, golden * radius)
    for (n, pt) in enumerate(pcenters)
        domonth(pt, radius, year, (month - 1) + n, img = img)
    end
    # center pentagon is different
    domonth(O, radius, year, month + 5, initrot = pi/5, img = img)
    finish()
    preview()
end

function drawcalendar(fname, ftype, imname)
    # width of 110 fits inside A/A4 paper, 155 just fits inside A3
    draw6months(fname * "1-6."  * ftype, 2018, 1, 105, img = imname)
    info("created: $(fname)1-6.$(ftype)")
    draw6months(fname * "7-12." * ftype, 2018, 7, 105, img = imname)
    info("created: $(fname)7-12.$(ftype)")
end

# filename, filetype, background image in current directory
drawcalendar("calendar", "pdf", "hokusai.png")
