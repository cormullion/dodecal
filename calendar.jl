using Luxor, Dates

pentagon(pos, radius, ang = 0) = ngon(pos, radius, 5, ang, vertices = true)

bigfont = "Barlow-Black"
smallfont = "Barlow-Semibold"

function drawmonth(year, month, radius)
    # origin is center of pentagon
    @layer begin
        rotate(π)
        fontsize(18)
        fontface(bigfont)
        text(string(Dates.monthname(Date(year, month, 1))), Point(0, -radius / 2 + 5), halign = :center)
        translate(0, radius / 6 - 5)
        lengthofmonth = Dates.daysinmonth(Date(year, month, 1))
        days = Tiler(radius + 30, radius + 10, 6, 7)  # 6 is max poss weeks
        pts = map(first, collect(days))
        # In Europe, first day of week (and first column) is Monday
        # Find difference between first Monday of month
        # and day 1 of month, then shift to first column
        # In the US, if Sunday is first column, use 9 not 8
        doff = mod1(8 - Dates.day(Dates.tofirst(Date(year, month, 1), 1)), 7)
        fontsize(9)
        fontface(smallfont)
        for d in 1:lengthofmonth
            # different colour for weekends, in Europe
            # In US, don't add that 1
            (d + doff + 1) % 7 < 2 ? sethue("purple") : sethue("black") # weekend
            pt = pts[d + doff]
            text(string(d), pt, halign = :center)
        end
        # add julia logo and year
        @layer begin
            translate(0, radius / 1.7)
            juliacircles(2)
            sethue("black")
            text("$year", O + (0, 10), halign = :center)
        end
    end
    return true
end

function drawflaps(radius, initrot, flapwidth, month)
    # initrot is non 0 when it's the center pentagon
    @layer begin
        if initrot == 0.0
            flapsideinner = pentagon(O, radius, deg2rad(108 / 2))[2:5]
            flapsideouter = pentagon(O, radius + flapwidth, deg2rad(108 / 2))[2:5]
            month < 6 ? edge = 1 : edge = 2
            for flap in [edge, 3]
                startflap = flapsideinner[flap]
                flapcorner1 = between(flapsideouter[flap], flapsideouter[flap + 1], 0.2)
                flapcorner2 = between(flapsideouter[flap], flapsideouter[flap + 1], 0.7)
                endflap = flapsideinner[flap + 1]
                poly([startflap, flapcorner1, flapcorner2, endflap], :stroke)
            end
        end
    end
    return true
end

function domonth(
        pt, radius, year, month;
        initrot = 0,
        flapwidth = 25,
        image = "",
        image_opacity = 0.25
    )
    println("drawing year $year, month $month")
    rot = slope(O, pt)
    @layer begin
        translate(pt)
        rotate(initrot)
        if image != ""
            @layer begin
                im = readpng(image)
                rotate(rot - π / 2)
                bx = BoundingBox(ngon(O, radius, 5, π / 10, :clip))
                scale(boxwidth(bx) / min(im.width, im.height))
                placeimage(im, O, image_opacity, centered = true)
                clipreset()
            end
        end
        # poss Cairo/Luxor bug, reset is needed after image transparency:
        setopacity(1.0)
        poly(pentagon(O, radius), :stroke, close = true)
        # rotate ready for text entry:
        rotate(rot + π / 2)
        drawflaps(radius, initrot, flapwidth, month)
        drawmonth(year, month, radius)
    end
    return true
end

function draw6months(
        fname, year, month, radius;
        img = "",
        image_opacity = 0.4
    )
    Drawing("A", fname)
    origin()
    background("white")
    sethue("black")
    setline(0.15)
    pcenters = pentagon(O, MathConstants.golden * radius)
    for (n, pt) in enumerate(pcenters)
        domonth(pt, radius, year, (month - 1) + n, image = img, image_opacity = 0.4)
    end
    # center pentagon is different
    domonth(O, radius, year, month + 5, initrot = π / 5, image = img, image_opacity = 0.4)
    finish()
    return preview()
end

function drawcalendar(year, fname, ftype, imgname)
    @info("creating $(fname)1-6.$(ftype)")
    # fname, year, month, radius, img, image_opacity
    # radius of 105 fits inside A/A4 paper
    draw6months(fname * "1-6." * ftype, year, 1, 105, img = imgname, image_opacity = 0.4)
    @info("creating $(fname)7-12.$(ftype)")
    draw6months(fname * "7-12." * ftype, year, 7, 105, img = imgname, image_opacity = 0.4)
end

# year, filename, filetype, background PNG image
drawcalendar(2026, "calendar", "pdf", "hokusai.png")
